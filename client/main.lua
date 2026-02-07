-- client.lua
local ESX = exports["es_extended"]:getSharedObject()
local isScoreboardVisible = false
local isAdmin = false

-- Función para mostrar/ocultar scoreboard
function toggleScoreboard()
    isScoreboardVisible = not isScoreboardVisible
    SetNuiFocus(isScoreboardVisible, isScoreboardVisible)

    if isScoreboardVisible then
        TriggerServerEvent('scoreboard:requestData')
        TriggerServerEvent('scoreboard:playerOpened')
    else
        TriggerServerEvent('scoreboard:playerClosed')
    end

    SendNUIMessage({
        type = "toggleScoreboard",
        show = isScoreboardVisible
    })
end

-- Controles optimizados
CreateThread(function()
    while true do
        Wait(100) -- Optimizado para mejor rendimiento

        if IsControlJustPressed(0, 168) then -- F7
            toggleScoreboard()
        end

        if isScoreboardVisible and IsControlJustPressed(0, 177) then -- ESC
            toggleScoreboard()
        end
    end
end)

-- Thread de actualización optimizado
CreateThread(function()
    while true do
        Wait(5000)
        if isScoreboardVisible then
            TriggerServerEvent('scoreboard:requestData')
        end
    end
end)

-- Eventos del servidor
RegisterNetEvent('scoreboard:updateData')
AddEventHandler('scoreboard:updateData', function(data)
    isAdmin = data.isAdmin or false

    SendNUIMessage({
        type = "updateData",
        playersOnline = data.playersOnline,
        jobCounts = data.jobCounts,
        robberyStatus = data.robberyStatus,
        playerData = data.playerData,
        isAdmin = isAdmin,
        config = data.config
    })
end)

-- Callbacks desde NUI
RegisterNUICallback('closeScoreboard', function(data, cb)
    toggleScoreboard()
    cb('ok')
end)

RegisterNUICallback('changeJob', function(data, cb)
    if isAdmin then
        TriggerServerEvent('scoreboard:changeJob', data.job)
    end
    cb('ok')
end)

-- Callbacks para el sistema de robos
RegisterNUICallback('requestRobbery', function(data, cb)
    TriggerServerEvent('scoreboard:requestRobbery', data.robberyName, data.robberyLabel)
    cb('ok')
end)

RegisterNUICallback('respondRobberyRequest', function(data, cb)
    TriggerServerEvent('scoreboard:respondRobberyRequest', data.robberyName, data.accepted)
    cb('ok')
end)

RegisterNUICallback('getPlayersData', function(data, cb)
    TriggerServerEvent('scoreboard:requestPlayersData')
    cb('ok')
end)

-- Eventos para el sistema de robos
RegisterNetEvent('scoreboard:showPoliceConfirmation')
AddEventHandler('scoreboard:showPoliceConfirmation', function(data)
    SendNUIMessage({
        type = "showPoliceConfirmation",
        robberyName = data.robberyName,
        robberyLabel = data.robberyLabel,
        playerName = data.playerName
    })
end)

-- Evento para recibir datos de jugadores
RegisterNetEvent('scoreboard:updatePlayersData')
AddEventHandler('scoreboard:updatePlayersData', function(players)
    SendNUIMessage({
        type = "updatePlayers",
        players = players
    })
end)

-- Thread de actualización ahora se maneja en las funciones startUpdateThread/stopUpdateThread