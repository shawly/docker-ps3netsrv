#!/usr/bin/env bash

# run this script as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

if [ ! -d "tests/" ]; then
    echo "Please run this script from the root of the project"
    exit
fi

function cleanup {
    rm -rf tests/games
}

function create_dummy_file {
    local dir="tests/games/$1"
    local filename=$2
    local ext=$3
    local owner=$4
    local group=$5
    local path="${dir}/${filename}.${ext}"
    echo "Creating dummy file: ${path}"
    mkdir -p "${dir}"
    touch "${path}"
    chown -v "$owner:$group" "${path}"
}

function create_dummy_ps3game {
    local dir="tests/games/$1"
    local foldername=$2
    local owner=$3
    local group=$4
    local path="${dir}/${foldername}"
    echo "Creating dummy game folder: ${path}"
    mkdir -p "${path}/PS3_GAME"
    touch "${path}/PS3_DISC.SFB"
    touch "${path}/PS3_GAME/PARAM.SFO"
    chown -Rv "$owner:$group" "${path}"
}

function create_linked_ini {
    local dir="tests/games/$1"
    local owner=$2
    local group=$3
    local path="${dir}.INI"
    echo "Creating linked ini file: ${path}"
    # Read content from stdin and write to the .ini file
    cat > "${path}"
    chown "$owner:$group" "${path}"
}

cleanup

mkdir -p tests/games/PS3ISO \
            tests/games/PS2ISO \
            tests/games/PKG \
            tests/games/PSXISO \
            tests/games/snes \
            tests/games/gba

chown -Rv 1000:1000 tests/games/PS3ISO

create_dummy_file "PS3ISO" "dummy_the_game" "iso" "root" "root"
chmod 0600 tests/games/PS3ISO/dummy_the_game.iso

create_dummy_file "PS3ISO" "dummy_the_game_3" "iso" "1000" "nogroup"

create_dummy_ps3game "GAMES" "DUMMY_THE_GAME" "nobody" "nogroup"
chown -Rv 1000:nogroup tests/games/GAMES/DUMMY_THE_GAME/PS3_GAME

create_dummy_ps3game "GAMES" "DUMMY_THE_GAME_2" "nobody" "nogroup"
chown -Rv nobody:nogroup tests/games/GAMES/DUMMY_THE_GAME/PS3_GAME

create_dummy_file "PS2ISO" "dummy_the_prequel" "iso" "nobody" "1000"

create_dummy_file "PKG" "dummy_the_dlc" "pkg" "nobody" "nogroup"

create_dummy_file "PSXISO" "dummy_the_original" "cue" "1000" "nogroup"
create_dummy_file "PSXISO" "dummy_the_original" "bin" "1000" "nogroup"

create_dummy_file "snes" "rom" "sfc" "nobody" "nogroup"
create_dummy_file "gba" "rom" "gba" "1000" "1000"
create_dummy_file "gba" "rom2" "gba" "root" "root"
chmod 600 tests/games/gba/rom2.gba

mkdir -p tests/games/unreadable
chmod 700 tests/games/unreadable
chown root:root tests/games/unreadable

create_linked_ini "ROMS" "nobody" "nogroup" <<EOF
/games/snes
/games/gba
/games/unreadable
/test
EOF
