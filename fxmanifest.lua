fx_version 'cerulean'
game 'gta5'

author 'MARFY | QBCore Team'
version '1.8.0'

shared_script 'config.lua'

client_script 'client/main.lua'

server_scripts  {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/reset.css',
    'html/profanity.js',
    'html/script.js',
    'html/song.mp3'
}

dependencies {
    'qb-core',
    'qb-spawn'
}

lua54 'yes'