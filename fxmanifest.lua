-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'Tu Nombre'
description 'Sistema de Scoreboard para ESX Legacy'
version '1.0.0'

dependencies {
    'es_extended'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/flecca.jpg',
    'html/img/pacific.jpg',
    'html/img/jewel.jpg',
    'html/img/247.jpeg'
}