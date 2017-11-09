#!/usr/bin/env bash

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun_facts.txt"

ES_DIR="/etc/emulationstation"
SYSTEMS_ARRAY=()
ES_SYSTEMS_CFG="$ES_DIR/es_systems.cfg"
DEFAULT_FONT="$ES_DIR/themes/carbon/art/Cabin-Bold.ttf"

function check_dependencies() {
    if ! which convert > /dev/null; then
        echo "ERROR: The imagemagick package is not installed!"
        echo "Please, install it with 'sudo apt-get install imagemagick'."
        exit 1
    fi
    if [[ -n "$DISPLAY" ]] && ! which feh  > /dev/null; then
        echo "ERROR: The feh package is not installed!"
        echo "Please, install it with 'sudo apt-get install feh'."
        exit 1
    fi
}

check_dependencies

#~ function list_systems() {
    #~ xmlstarlet sel -t -v "/systemList/system/name" "$ES_SYSTEMS_CFG" | grep -v retropie
#~ }

#~ function get_systems() {
    #~ [[ -n "$SISTEMS_ARRAY" ]] && return 0
    #~ local system_list
    #~ system_list=$(list_systems)
    #~ SYSTEMS_ARRAY=($system_list)
    
    #~ for SYSTEM in ${SYSTEMS_ARRAY[@]}; do
        #~ echo "$SYSTEM"
    #~ done
#~ }

function get_current_theme() {
    #~ xmlstarlet sel -t -v "string" "/home/pi/.emulationstation/es_settings.cfg"
    current_theme=$(grep "name=\"ThemeSet\"" "/home/pi/.emulationstation/es_settings.cfg" | sed -n -e "s/^.*value=['\"]\(.*\)['\"].*/\1/p")
    #~ echo "$current_theme"
}

function get_theme_font() {
    get_current_theme
    if [[ -n "$(find "$ES_DIR/themes/$current_theme/art" -type f -name '*.ttf')" ]]; then
        font="$(find "$ES_DIR/themes/$current_theme/art" -type f -name '*.ttf')"
        #~ echo $font
    else
        font=$DEFAULT_FONT
        #~ echo $font
    fi
}

function create_fun_fact() {
    get_theme_font
    random_fact="$(shuf -n 1 $FUN_FACTS_TXT)"
    #~ echo "$random_fact"
    echo -e "Creating Fun Fact!\u2122 splashscreen ..."
    convert splash4-3.png \
        -size 1000x100 \
        -background none \
        -fill white \
        -font "$font" \
        caption:"$random_fact" \
        -gravity south \
        -geometry +0+25 \
        -composite \
        result.png
    echo -e "Fun Fact!\u2122 splashscreen successfully created!"
}

create_fun_fact
    
feh --full-screen result.png