-- server.lua
local ESX = exports["es_extended"]:getSharedObject()

-- Grupos de administradores
Config.AdminGroups = {"admin", "superadmin", "owner"}

-- Sistema de robos
local robberyRequests = {}
local robberiesInProgress = {}

-- Sistema de optimización
local activeScoreboards = {} -- Jugadores que tienen el scoreboard abierto
local cachedJobCounts = {}
local cachedRobberyStatus = {}
local lastCacheUpdate = 0
local CACHE_DURATION = 3000 -- 3 segundos de caché

-- Función para contar jugadores por trabajo
function getJobCounts()
    local jobCounts = {}

    -- Inicializar contadores
    for _, job in pairs(Config.Jobs) do
        jobCounts[job.name] = 0
    end

    -- Contar jugadores en cada trabajo
    local players = ESX.GetPlayers()
    for _, playerId in pairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            local jobName = xPlayer.getJob().name
            if jobCounts[jobName] ~= nil then
                jobCounts[jobName] = jobCounts[jobName] + 1
            end
        end
    end

    return jobCounts
end

-- Función optimizada para verificar estado de los robos
function getRobberyStatus(jobCounts)
    local robberyStatus = {}

    for _, robbery in pairs(Config.Robberies) do
        local requiredCount = robbery.requiredCount
        local currentCount = jobCounts[robbery.requiredJob] or 0

        robberyStatus[robbery.name] = {
            label = robbery.label,
            icon = robbery.icon,
            active = currentCount >= requiredCount,
            currentCount = currentCount,
            requiredCount = requiredCount,
            requiredJob = robbery.requiredJob,
            inProgress = robberiesInProgress[robbery.name] or false
        }
    end

    return robberyStatus
end

-- Función para obtener datos del jugador
function getPlayerData(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local playerData = {
        name = GetPlayerName(source),
        job = xPlayer.getJob().name,
        jobLabel = xPlayer.getJob().label,
        steamAvatar = nil
    }

    -- Obtener avatar de Steam si está disponible
    local steamId = nil
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local identifier = GetPlayerIdentifier(source, i)
        if string.find(identifier, "steam:") then
            steamId = string.gsub(identifier, "steam:", "")
            break
        end
    end

    if steamId then
        -- Convertir Steam ID a Steam64
        local steam64 = tonumber(steamId, 16)
        if steam64 then
            steam64 = steam64 + 76561197960265728
            playerData.steamAvatar = "https://steamcommunity.com/profiles/" .. steam64 .. "/avatar_full.jpg"
        end
    end

    return playerData
end

-- Función para verificar si el jugador es admin
function isPlayerAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    for _, group in pairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            return true
        end
    end
    return false
end

-- Función para obtener datos del scoreboard
function getScoreboardData(source)
    local playersOnline = #ESX.GetPlayers()
    local jobCounts = getJobCounts()
    local robberyStatus = getRobberyStatus(jobCounts)
    local playerData = getPlayerData(source)
    local isAdmin = isPlayerAdmin(source)

    return {
        playersOnline = playersOnline,
        jobCounts = jobCounts,
        robberyStatus = robberyStatus,
        playerData = playerData,
        isAdmin = isAdmin,
        config = Config
    }
end

-- Función para actualizar solo jugadores con scoreboard activo
function updateActiveScoreboards()
    if not next(activeScoreboards) then return end

    for playerId, _ in pairs(activeScoreboards) do
        if GetPlayerName(playerId) then -- Verificar que el jugador siga conectado
            local data = getScoreboardData(playerId)
            TriggerClientEvent('scoreboard:updateData', playerId, data)
        else
            -- Limpiar jugadores desconectados
            activeScoreboards[playerId] = nil
        end
    end
end

-- Evento para solicitar datos
RegisterServerEvent('scoreboard:requestData')
AddEventHandler('scoreboard:requestData', function()
    local source = source
    local data = getScoreboardData(source)
    TriggerClientEvent('scoreboard:updateData', source, data)
end)

-- Eventos para tracking de jugadores activos (optimización)
RegisterServerEvent('scoreboard:playerOpened')
AddEventHandler('scoreboard:playerOpened', function()
    local source = source
    activeScoreboards[source] = true
end)

RegisterServerEvent('scoreboard:playerClosed')
AddEventHandler('scoreboard:playerClosed', function()
    local source = source
    activeScoreboards[source] = nil
end)

-- Evento para cambiar trabajo (solo admins)
RegisterNetEvent('scoreboard:changeJob')
AddEventHandler('scoreboard:changeJob', function(jobName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    -- Verificar si el jugador es admin
    if not isPlayerAdmin(source) then
        TriggerClientEvent('esx:showNotification', source, '~r~No tienes permisos para cambiar de trabajo')
        return
    end

    -- Verificar si el trabajo existe
    local jobExists = false
    for _, job in pairs(Config.Jobs) do
        if job.name == jobName then
            jobExists = true
            break
        end
    end

    if not jobExists then
        TriggerClientEvent('esx:showNotification', source, '~r~Trabajo no válido')
        return
    end

    -- Cambiar trabajo
    xPlayer.setJob(jobName, 0)
    TriggerClientEvent('esx:showNotification', source, '~g~Trabajo cambiado a: ' .. jobName)

    -- Actualizar datos para el jugador que cambió de trabajo
    local data = getScoreboardData(source)
    TriggerClientEvent('scoreboard:updateData', source, data)
end)

-- Comando para abrir scoreboard (alternativo)
RegisterCommand('scoreboard', function(source, args, rawCommand)
    TriggerClientEvent('scoreboard:requestData', source)
end, false)

-- Evento para solicitar robo
RegisterNetEvent('scoreboard:requestRobbery')
AddEventHandler('scoreboard:requestRobbery', function(robberyName, robberyLabel)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    -- Verificar si el robo existe
    local robberyExists = false
    for _, robbery in pairs(Config.Robberies) do
        if robbery.name == robberyName then
            robberyExists = true
            break
        end
    end

    if not robberyExists then
        TriggerClientEvent('esx:showNotification', source, '~r~Robo no válido')
        return
    end

    -- Verificar si el robo ya está en progreso
    if robberiesInProgress[robberyName] then
        TriggerClientEvent('esx:showNotification', source, '~r~Este robo ya está en progreso')
        return
    end

    -- Guardar la solicitud
    robberyRequests[robberyName] = {
        playerId = source,
        playerName = GetPlayerName(source),
        robberyLabel = robberyLabel,
        timestamp = os.time()
    }

    -- Notificar a todos los policías
    local players = ESX.GetPlayers()
    for _, playerId in pairs(players) do
        local xTargetPlayer = ESX.GetPlayerFromId(playerId)
        if xTargetPlayer and xTargetPlayer.getJob().name == 'police' then
            TriggerClientEvent('scoreboard:showPoliceConfirmation', playerId, {
                robberyName = robberyName,
                robberyLabel = robberyLabel,
                playerName = GetPlayerName(source)
            })
        end
    end

    TriggerClientEvent('esx:showNotification', source, '~y~Solicitud de robo enviada a la policía')
end)

-- Evento para responder a solicitud de robo
RegisterNetEvent('scoreboard:respondRobberyRequest')
AddEventHandler('scoreboard:respondRobberyRequest', function(robberyName, accepted)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or xPlayer.getJob().name ~= 'police' then
        TriggerClientEvent('esx:showNotification', source, '~r~Solo la policía puede responder')
        return
    end

    local request = robberyRequests[robberyName]
    if not request then
        TriggerClientEvent('esx:showNotification', source, '~r~Solicitud no encontrada')
        return
    end

    local requesterId = request.playerId
    local requesterName = request.playerName
    local robberyLabel = request.robberyLabel

    if accepted then
        -- Marcar robo como en progreso
        robberiesInProgress[robberyName] = true

        -- Notificar al solicitante
        TriggerClientEvent('esx:showNotification', requesterId, '~g~¡Robo aprobado! Puedes comenzar')

        -- Notificar a la policía
        TriggerClientEvent('esx:showNotification', source, '~g~Robo aprobado para ' .. requesterName)

        -- Actualizar solo jugadores con scoreboard activo
        updateActiveScoreboards()

        -- Programar finalización automática del robo (30 minutos)
        SetTimeout(1800000, function() -- 30 minutos
            robberiesInProgress[robberyName] = nil
            updateActiveScoreboards()
        end)
    else
        -- Notificar al solicitante
        TriggerClientEvent('esx:showNotification', requesterId, '~r~Robo rechazado por la policía')

        -- Notificar a la policía
        TriggerClientEvent('esx:showNotification', source, '~r~Robo rechazado para ' .. requesterName)
    end

    -- Limpiar solicitud
    robberyRequests[robberyName] = nil
end)

-- Comando para finalizar robo manualmente (solo admins)
RegisterCommand('finishrobbery', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not isPlayerAdmin(source) then
        TriggerClientEvent('esx:showNotification', source, '~r~No tienes permisos')
        return
    end

    if not args[1] then
        TriggerClientEvent('esx:showNotification', source, '~r~Uso: /finishrobbery <nombre_robo>')
        return
    end

    local robberyName = args[1]

    if robberiesInProgress[robberyName] then
        robberiesInProgress[robberyName] = nil
        TriggerClientEvent('esx:showNotification', source, '~g~Robo finalizado: ' .. robberyName)

        -- Actualizar solo jugadores con scoreboard activo
        updateActiveScoreboards()
    else
        TriggerClientEvent('esx:showNotification', source, '~r~Este robo no está en progreso')
    end
end, false)

-- Thread optimizado: solo actualiza jugadores con scoreboard activo
CreateThread(function()
    while true do
        Wait(10000) -- Cada 10 segundos

        -- Solo procesar si hay jugadores con scoreboard activo
        if next(activeScoreboards) then
            updateActiveScoreboards()
        end
    end
end)

-- Función para obtener datos de todos los jugadores
function getAllPlayersData()
    local playersData = {}
    local players = ESX.GetPlayers()

    for _, playerId in pairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            local playerData = {
                id = playerId,
                name = xPlayer.getName(),
                job = xPlayer.getJob().name,
                isAdmin = isPlayerAdmin(playerId),
                ping = GetPlayerPing(playerId),
                steamAvatar = nil
            }

            -- Obtener avatar de Steam si está disponible
            local steamId = xPlayer.getIdentifier()
            if steamId then
                -- Aquí podrías implementar una función para obtener el avatar de Steam
                -- Por ahora lo dejamos como nil
                playerData.steamAvatar = nil
            end

            table.insert(playersData, playerData)
        end
    end

    return playersData
end

-- Evento para solicitar datos de jugadores
RegisterServerEvent('scoreboard:requestPlayersData')
AddEventHandler('scoreboard:requestPlayersData', function()
    local source = source
    local playersData = getAllPlayersData()
    TriggerClientEvent('scoreboard:updatePlayersData', source, playersData)
end)

-- Limpiar jugadores desconectados del tracking
AddEventHandler('playerDropped', function(reason)
    local source = source
    activeScoreboards[source] = nil
end)