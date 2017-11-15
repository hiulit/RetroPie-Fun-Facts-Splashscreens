#!/usr/bin/env bash

# Fun Facts splashscreens
# A tool for RetroPie to create splashscreens with random video game related fun facts.
#
# Requirements:
# - Retropie 4.x.x
# - Imagemagick package

#~ user="$SUDO_USER"
#~ [[ -z "$user" ]] && user="$(id -un)"
#~ home="$(eval echo ~$user)"

home="/home/pi"

readonly ES_DIR=("$home/.emulationstation" "/etc/emulationstation")
readonly ES_THEMES_DIR="/etc/emulationstation/themes"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun_facts.txt"
readonly DEFAULT_SPLASH="$SCRIPT_DIR/splash4-3.png"
readonly RESULT_SPLASH="$home/RetroPie/splashscreens/fun-fact-splashscreen.png"

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

function check_safe_exit_boot_script() {
    if [[ "$(tail -n1 /etc/rc.local)" != "exit 0" ]]; then
        sed -i -e '$i \exit 0\' "/etc/rc.local"
    fi
}

function check_boot_script() {
    grep "$SCRIPT_DIR" "/etc/rc.local"
}

function add_boot_script() {
    sed -i -e '$i \'"$home"'/es-fun-facts-splashscreens/es-fun-facts-splashscreens.sh --create-fun-fact &' "/etc/rc.local"
    check_safe_exit_boot_script
}

function remove_boot_script() {
    sed -i -e "s%$(check_boot_script)%%g" "/etc/rc.local"
}

function usage() {
    echo
    echo "USAGE: sudo ./$(basename $0) [options]"
    echo
    echo "Use '--help' to see all the options"
    echo
}

function get_options() {
    if [[ -z "$1" ]]; then
        usage
    fi
    while [[ -n "$1" ]]; do
        case "$1" in
#H -h, --help       Print the help message and exit.
            -h|--help)
                echo
                sed '/^#H /!d; s/^#H //' "$0"
                echo
                exit 0
                ;;
#H --enable-boot    Enable script to be launch at boot.
            --enable-boot)
                if [[ -z "$(check_boot_script)" ]]; then
                    add_boot_script
                    echo "Script enabled to be launched at boot."
                    exit 0
                else
                    echo "ERROR: launch at boot is already enabled." >&2
                    exit 1
                fi
                ;;
#H --disable-boot   Disable script to be launch at boot.
            --disable-boot)
                if [[ -n "$(check_boot_script)" ]]; then
                    remove_boot_script
                    echo "Script disabled to be launched at boot."
                    exit 0
                else
                    echo "ERROR: launch at boot is already disabled." >&2
                    exit 1
                fi
                ;;
#H --create-fun-fact Create Fun Fact Splashscreen.
            --create-fun-fact)
                create_fun_fact
                exit 0
                ;;
            *)
                echo "ERROR: invalid option \"$1\"" >&2
                exit 2
                ;;
        esac
    done
}

function get_current_theme() {
    sed -n "/name=\"ThemeSet\"/ s/^.*value=['\"]\(.*\)['\"].*/\1/p" "$home/.emulationstation/es_settings.cfg"
}

function get_font() {
    local theme="$(get_current_theme)"
    [[ -z "$theme" ]] && theme="carbon"

    local font="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed')]/textlist/fontPath" \
        "$ES_THEMES_DIR/$theme/$theme.xml" 2> /dev/null)"

    if [[ -n "$font" ]]; then
        font="$ES_THEMES_DIR/$theme/$font"
    else
        # note: the find below returns the full path file name
        font="$(find "$ES_THEMES_DIR/$theme/" -type f -name '*.ttf' -print -quit)"
        if [[ -z "$font" ]]; then
            echo "ERROR: Unable to get the font from the \"$theme\" theme files." >&2
            echo "Aborting..." >&2
            exit 1
        fi
    fi

    echo "$font"
}

function create_fun_fact() {
    local splash="$1"
    local font="$(get_font)"

    [[ -f "$splash" ]] || splash="$DEFAULT_SPLASH"

    random_fact="$(shuf -n 1 "$FUN_FACTS_TXT")"

    echo -e "Creating Fun Fact!\u2122 splashscreen..."

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
        "$RESULT_SPLASH" \
    && echo -e "Fun Fact!\u2122 splashscreen successfully created!"
}

check_dependencies

get_options "$@"

#~ create_fun_fact "$1"

# feh --full-screen "$RESULT_SPLASH"
