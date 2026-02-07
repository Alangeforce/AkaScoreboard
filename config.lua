Config = {}

-- ========================================
-- CONFIGURACIÓN DE TÍTULOS Y TEXTOS
-- ========================================
Config.ServerName = "M Roleplay"        -- Nombre del servidor que aparece en el header principal
Config.ScoreboardTitle = "Scoreboard"   -- Título del scoreboard que aparece debajo del nombre del servidor

-- Ejemplos de personalización:
-- Config.ServerName = "Mi Servidor RP"
-- Config.ScoreboardTitle = "Panel de Jugadores"

-- Configuración de trabajos
Config.Jobs = {
    {
        name = "police",
        label = "Policía",
        icon = "fas fa-shield-alt"
    },
    {
        name = "ambulance",
        label = "Médico",
        icon = "fas fa-ambulance"
    },
    {
        name = "mechanic",
        label = "Mecánico",
        icon = "fas fa-wrench"
    },
    {
        name = "uwu",
        label = "Cafe UwU",
        icon = "fas fa-coffee"
    },
    {
        name = "unemployed",
        label = "Desempleado",
        icon = "fas fa-user"
    },
    {
        name = "taxi",
        label = "Taxista",
        icon = "fas fa-taxi"
    },
    {
        name = "cardealer",
        label = "Concesionario",
        icon = "fas fa-car"
    },
    {
        name = "realestate",
        label = "Inmobiliaria",
        icon = "fas fa-home"
    },
    {
        name = "banker",
        label = "Banquero",
        icon = "fas fa-university"
    }
}

-- Configuración de robos
Config.Robberies = {
    {
        name = "fleeca_bank",
        label = "Banco Fleeca",
        icon = "fas fa-university",
        requiredJob = "police",
        requiredCount = 2
    },
    {
        name = "pacific_bank",
        label = "Banco Pacific",
        icon = "fas fa-landmark",
        requiredJob = "police",
        requiredCount = 4
    },
    {
        name = "jewelry_store",
        label = "Joyería",
        icon = "fas fa-gem",
        requiredJob = "police",
        requiredCount = 1
    },
    {
        name = "convenience_store",
        label = "Tienda 24/7",
        icon = "fas fa-store",
        requiredJob = "police",
        requiredCount = 1
    },
    {
        name = "paleto_bank",
        label = "Banco Paleto",
        icon = "fas fa-piggy-bank",
        requiredJob = "police",
        requiredCount = 3
    }
}
