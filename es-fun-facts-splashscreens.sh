#!/usr/bin/env bash

# Fun Facts splashscreens
# A tool for RetroPie to create splashscreens with random video game related fun facts.
#
# Requirements:
# - Retropie 4.x.x
# - Imagemagick package

home="$(find /home -type d -name RetroPie -print -quit 2>/dev/null)"
home="${home%/RetroPie}"

readonly ES_THEMES_DIR="/etc/emulationstation/themes"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly FUN_FACTS_CFG="$SCRIPT_DIR/fun_facts_settings.cfg"
readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun_facts.txt"
readonly DEFAULT_SPLASH="$SCRIPT_DIR/retropie-default.png"
readonly DEFAULT_COLOR="white"
readonly RESULT_SPLASH="$home/RetroPie/splashscreens/fun-fact-splashscreen.png"
readonly RCLOCAL="/etc/rc.local"

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

SPLASH=
TEXT_COLOR=
ENABLE_BOOT_FLAG=0
DISABLE_BOOT_FLAG=0
CONFIG_FLAG=0

function usage() {
    echo
    echo "USAGE: sudo $0 [options]"
    echo
    echo "Use '--help' to see all the options."
    echo
}

function is_retropie() {
    [[ -d "$home/RetroPie" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}

function check_dependencies() {
    if ! which convert > /dev/null; then
        echo -e "${RED}ERROR: The imagemagick package is not installed!${NC}" >&2
        echo "Please, install it with 'sudo apt-get install imagemagick'." >&2
        exit 1
    fi
}

function set_config() {
    sed -i "s|^\($1\s*=\s*\).*|\1\"$2\"|" "$FUN_FACTS_CFG"
    echo -e "${GREEN}\"$1\" set to \"$2\".${NC}"
}

function get_config() {
    local config
    config="$(grep -Po "(?<=^$1 = ).*" "$FUN_FACTS_CFG")"
    config="${config%\"}"
    config="${config#\"}"
    echo "$config"
}

function assure_safe_exit_boot_script() {
    grep -q '^exit 0$' "$RCLOCAL" || echo "exit 0" >> "$RCLOCAL"
}

function check_boot_script() {
    grep -q "$SCRIPT_DIR" "$RCLOCAL"
}

function enable_boot_script() {
    local command="\"$SCRIPT_DIR/$(basename "$0")\" --create-fun-fact --splash \"$1\" --text-color \"$2\" \&"
    disable_boot_script # deleting any previous config (do nothing if there isn't).
    sed -i "s|^exit 0$|${command}\\nexit 0|" "$RCLOCAL"
    assure_safe_exit_boot_script
    check_boot_script
}

function disable_boot_script() {
    sed -i "/$(basename "$0")/d" "$RCLOCAL"
    assure_safe_exit_boot_script
    ! check_boot_script
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
        # note: the find below returns the full path file name.
        font="$(find "$ES_THEMES_DIR/$theme/" -type f -name '*.ttf' -print -quit)"
        if [[ -z "$font" ]]; then
            echo "${RED}ERROR: Unable to get the font from the \"$theme\" theme files.${NC}" >&2
            echo "Aborting ..." >&2
            exit 1
        fi
    fi

    echo "$font"
}

function create_fun_fact() {
    local splash="$1"
    local color="$2"
    local font="$(get_font)"

    [[ -f "$splash" ]] || splash="$DEFAULT_SPLASH"
    [[ -n "$color" ]] || color="$DEFAULT_COLOR"

    random_fact="$(shuf -n 1 "$FUN_FACTS_TXT")"

    echo
    echo -e "Creating Fun Fact!\u2122 splashscreen ..."

    convert "$splash" \
        -size 1000x100 \
        -background none \
        -fill "$color" \
        -interline-spacing 2 \
        -font "$font" \
        caption:"$random_fact" \
        -gravity south \
        -geometry +0+25 \
        -composite \
        "$RESULT_SPLASH" \
    && echo -e "${GREEN}Fun Fact!\u2122 splashscreen successfully created!${NC}"
}

function validate_splash() {
    if [[ ! -f "$1" ]]; then
        echo >&2
        echo -e "${RED}ERROR: '$1' file not found!${NC}" >&2
        if [[ "$CONFIG_FLAG" == 1 ]]; then
            echo "Check the 'splashscreen_path' value in '$FUN_FACTS_CFG'" >&2
        fi
        exit 1
    fi
}

function validate_color() {
    if convert -list color | grep -q "^$1\b"; then
        return 0
    fi
    
    echo >&2
    echo -e "${RED}ERROR: invalid color \"$1\".${NC}" >&2
    if [[ "$CONFIG_FLAG" == 1 ]]; then
        echo "Check the 'text_color' value in '$FUN_FACTS_CFG'" >&2
    fi
    echo >&2
    echo "Short list of available colors:" >&2
    echo "-------------------------------" >&2
    echo "black white gray gray10 gray25 gray50 gray75 gray90" >&2
    echo "pink red orange yellow green silver blue cyan purple brown" >&2
    echo >&2
    echo "TIP: run the 'convert -list color' command to get a full list." >&2
    echo >&2
    exit 1
}

function check_argument() { 
    # XXX: this method doesn't accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then 
        echo -e "${RED}ERROR: \"$1\" is missing an argument.${NC}" >&2 
        echo "$($0 --help)" >&2 
        return 1 
    fi 
}

function check_config() {
    CONFIG_FLAG=1
    SPLASH="$(get_config splashscreen_path)"
    TEXT_COLOR="$(get_config text_color)"
    
    if [[ -z "$SPLASH" ]]; then
        echo
        echo "'splashscreen_path' is not defined in 'fun_facts_settings.cfg'"
        echo "Switching to default splashscreen."
        SPLASH="$DEFAULT_SPLASH"
    fi
    
    if [[ -z "$TEXT_COLOR" ]]; then
        echo
        echo "'text_color' is not defined in 'fun_facts_settings.cfg'"
        echo "Switching to default color."
        TEXT_COLOR="$DEFAULT_COLOR"
    fi
    
    validate_splash "$SPLASH"
    validate_color "$TEXT_COLOR"
    
    echo
    echo "Splashscreen = '$SPLASH'"
    echo "Text color   = '$TEXT_COLOR'"
}

function get_options() {
    if [[ -z "$1" ]]; then
        usage
        exit 0
    fi

    while [[ -n "$1" ]]; do
        case "$1" in
#H -h, --help                   	        Print the help message and exit.
            -h|--help)
                echo
                sed '/^#H /!d; s/^#H //' "$0"
                echo
                exit 0
                ;;

#H -s, --splash [path/to/splashscreen]     Set which splashscreen to use.
            -s|--splash)
                check_argument "$1" "$2" || exit 1
                shift
                validate_splash "$1"
                SPLASH="$1"
                set_config "splashscreen_path" "$SPLASH"
                ;;

#H --text-color [color]           	        Set which text color to use.
            --text-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_color "$1"
                TEXT_COLOR="$1"
                set_config "text_color" "$TEXT_COLOR"
                ;;

#H --create-fun-fact            	        Create Fun Fact! splashscreen.
            --create-fun-fact)
                CREATE_SPLASH_FLAG=1
                ;;
                
#H --enable-boot                	        Enable script to be launch at boot.
            --enable-boot)
                ENABLE_BOOT_FLAG=1
                ;;

#H --disable-boot               	        Disable script to be launch at boot.
            --disable-boot)
                DISABLE_BOOT_FLAG=1
                ;;

            *)
                echo -e "${RED}ERROR: invalid option \"$1\"${NC}" >&2
                exit 2
                ;;
        esac
        shift
    done
}

function main() {
    check_dependencies
    
    # check if sudo is used.
    if [[ "$(id -u)" -ne 0 ]]; then
        echo -e "${RED}ERROR: Script must be run under sudo.${NC}" >&2
        usage
        exit 1
    fi
    
    if ! is_retropie; then
        echo -e "${RED}ERROR: RetroPie is not installed. Aborting...${NC}" >&2
        exit 1
    fi

    mkdir -p "$home/RetroPie/splashscreens"

    get_options "$@"

    if [[ "$CREATE_SPLASH_FLAG" == 1 ]]; then
        check_config
        create_fun_fact "$SPLASH" "$TEXT_COLOR"
    fi

    if [[ "$ENABLE_BOOT_FLAG" == 1 ]]; then
        check_config
        enable_boot_script "$SPLASH" "$TEXT_COLOR" || echo -e "${RED}ERROR: failed to enable script at boot.${NC}" >&2
    fi

    if [[ "$DISABLE_BOOT_FLAG" == 1 ]]; then
        disable_boot_script || echo -e "${RED}ERROR: failed to disable script at boot.${NC}" >&2
    fi
}

main "$@"
