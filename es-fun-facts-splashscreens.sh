#!/usr/bin/env bash

user="$SUDO_USER"
[[ -z "$user" ]] && user="$(id -un)"
home="$(eval echo ~$user)"

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun_facts.txt"
readonly DEFAULT_SPLASH="$SCRIPT_DIR/splash4-3.png"
readonly ES_DIR="/etc/emulationstation"

# TODO: DEFAUL_FONT shouldn't be hardcoded this way. What if theme maintainer change this font in the future?
readonly DEFAULT_FONT="$ES_DIR/themes/carbon/art/Cabin-Bold.ttf"

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

function get_current_theme() {
    grep "name=\"ThemeSet\"" "$home/.emulationstation/es_settings.cfg" | sed -n -e "s/^.*value=['\"]\(.*\)['\"].*/\1/p"
}

function get_theme_font() {
    xmlstarlet sel -t -v "/theme/view[contains(@name,'detailed')]/textlist/fontPath" "$ES_DIR/themes/$current_theme/$current_theme.xml" 2> /dev/null
}

# TODO: the logic here can be improved. ;)
function create_fun_fact() {
    current_theme="$(get_current_theme)"
    local theme_font="$(get_theme_font)"
    local splash="$1"

    if [[ ! -f "$splash" ]]; then
        splash="$DEFAULT_SPLASH"
    fi

    if [[ -z "$theme_font" ]]; then
        font="$DEFAULT_FONT"
    else
        font="$ES_DIR/themes/$current_theme/art/$(basename "$theme_font")"
    fi

    random_fact="$(shuf -n 1 "$FUN_FACTS_TXT")"

    echo -e "Creating Fun Fact!\u2122 splashscreen ..."

    convert "$splash" \
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

check_dependencies

create_fun_fact "$1"

feh --full-screen result.png
