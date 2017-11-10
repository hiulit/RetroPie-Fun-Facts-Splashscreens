#!/usr/bin/env bash

user="$SUDO_USER"
[[ -z "$user" ]] && user="$(id -un)"
home="$(eval echo ~$user)"

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun_facts.txt"

ES_DIR="/etc/emulationstation"
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

function get_current_theme() {
    grep "name=\"ThemeSet\"" "$home/.emulationstation/es_settings.cfg" | sed -n -e "s/^.*value=['\"]\(.*\)['\"].*/\1/p"
}

function get_theme_font() {
    xmlstarlet sel -t -v "/theme/view[contains(@name,'detailed')]/textlist/fontPath" "$ES_DIR/themes/$current_theme/$current_theme.xml" 2> /dev/null
}

function create_fun_fact() {
    current_theme=$(get_current_theme)
    theme_font=$(get_theme_font)
    
    if [[ -z "$theme_font" ]]; then
        font="$DEFAULT_FONT"
    else
        font="$ES_DIR/themes/$current_theme/art/$(basename $theme_font)"
    fi
    
    random_fact="$(shuf -n 1 $FUN_FACTS_TXT)"
    
    echo -e "Creating Fun Fact!\u2122 splashscreen ..."
    
    convert splash4-3.png \
        -size 1000x100 \
        -background none \
        -fill white \
        -interline-spacing 5 \
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