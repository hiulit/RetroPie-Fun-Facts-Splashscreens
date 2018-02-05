#!/usr/bin/env bash
# fun-facts-splashscreens.sh
#
# Fun Facts! Splashscreens for RetroPie.
# A tool for RetroPie to create splashscreens with random video game related fun facts.
#
# Author: hiulit
# Repository: https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens
# License: MIT License https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/blob/master/LICENSE
#
# Requirements:
# - Retropie 4.x.x
# - Imagemagick package


# Globals #############################################

user="$SUDO_USER"
[[ -z "$user" ]] && user="$(id -un)"

home="$(find /home -type d -name RetroPie -print -quit 2> /dev/null)"
home="${home%/RetroPie}"

readonly RP_DIR="$home/RetroPie"
readonly ES_THEMES_DIR="/etc/emulationstation/themes"
readonly SPLASH_LIST="/etc/splashscreen.list"
readonly RCLOCAL="/etc/rc.local"
readonly DEPENDENCIES=("imagemagick")

readonly SCRIPT_VERSION="1.5.0"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_CFG="$SCRIPT_DIR/fun-facts-splashscreens-settings.cfg"
readonly SCRIPT_TITLE="Fun Facts! Splashscreens for RetroPie"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to create splashscreens with random video game related fun facts."
readonly SCRIPTMODULE_DIR="/opt/retropie/supplementary/fun-facts-splashscreens"


# Variables ############################################

# Files
readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun-facts.txt"
readonly RESULT_SPLASH="$RP_DIR/splashscreens/fun-facts-splashscreen.png"
readonly LOG_FILE="$SCRIPT_DIR/fun-facts-splashscreens.log"

# Defaults
readonly DEFAULT_SPLASH="$SCRIPT_DIR/retropie-default.png"
readonly DEFAULT_COLOR="white"
readonly DEFAULT_BOOT_SCRIPT="false"
readonly DEFAULT_LOG="false"

# Dialogs
readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_ESC=255
readonly DIALOG_HEIGHT=18
readonly DIALOG_WIDTH=60

# Flags
GUI_FLAG=0
CONFIG_FLAG=0

# Global variables
SPLASH_PATH=
TEXT_COLOR=
BOOT_SCRIPT=
LOG=
OPTION=


# Functions ############################################

function is_retropie() {
    [[ -d "$RP_DIR" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}


function is_sudo() {
    [[ "$(id -u)" -eq 0 ]]
}


function check_log_file(){
    if [[ "$LOG" == "true" ]]; then
        if [[ ! -f "$LOG_FILE" ]]; then
            touch "$LOG_FILE"
            chown -R "$user":"$user" "$LOG_FILE"
        fi
    fi
}


function log() {
    check_log_file
    if [[ "$GUI_FLAG" -eq 1 ]] ; then
        if [[ "$LOG" == "true" ]]; then
            echo "$(date +%F\ %T) - (v$SCRIPT_VERSION) GUI: $* << ${FUNCNAME[@]:1:((${#FUNCNAME[@]}-3))} $OPTION" >> "$LOG_FILE" # -2 are log ... get_options main main
        fi
        echo "$*"
    else
        if [[ "$LOG" == "true" ]]; then
            echo "$(date +%F\ %T) - (v$SCRIPT_VERSION) $* << ${FUNCNAME[@]:1:((${#FUNCNAME[@]}-3))} $OPTION" >> "$LOG_FILE" # -2 are log ... get_options main main
        fi
        echo "$*" >&2
    fi
}


function check_dependencies() {
    local pkg
    for pkg in "${DEPENDENCIES[@]}";do
        if ! dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" > /dev/null; then
            log "ERROR: The '$pkg' package is not installed!"
            echo "Would you like to install it now?"
            local options=("Yes" "No")
            local option
            select option in "${options[@]}"; do
                case "$option" in
                    Yes)
                        if ! which apt-get > /dev/null; then
                            log "ERROR: Can't install '$pkg' automatically. Try to install it manually."
                            exit 1
                        else
                            sudo apt-get install "$pkg"
                            break
                        fi
                        ;;
                    No)
                        log "ERROR: Can't launch the script if the '$pkg' package is not installed."
                        exit 1
                        ;;
                    *)
                        echo "Invalid option. Choose a number between 1 and ${#options[@]}."
                        ;;
                esac
            done
        fi
    done
}


function check_argument() {
    # Note: this method doesn't accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        log "ERROR: '$1' is missing an argument."
        echo "Try 'sudo $0 --help' for more info." >&2
        return 1
    fi
}


function check_default_files() {
    if [[ ! -f "$DEFAULT_SPLASH" ]]; then
        if curl -s -f "https://raw.githubusercontent.com/RetroPie/retropie-splashscreens/master/retropie-default.png" -o "$DEFAULT_SPLASH"; then
            chown -R "$user":"$user" "$DEFAULT_SPLASH"
        else
            log "ERROR: Can't download default splashscreen."
        fi
    fi

    if [[ ! -f "$SCRIPT_CFG" ]]; then
        if curl -s -f  "https://raw.githubusercontent.com/hiulit/RetroPie-Fun-Facts-Splashscreens/master/fun-facts-splashscreens-settings.cfg" -o "$SCRIPT_CFG"; then
            chown -R "$user":"$user" "$SCRIPT_CFG"
        else
            log "ERROR: Can't download config file."
        fi
    fi

    if [[ ! -f "$FUN_FACTS_TXT" ]]; then
        if curl -s -f  "https://raw.githubusercontent.com/hiulit/RetroPie-Fun-Facts-Splashscreens/master/fun-facts.txt" -o "$FUN_FACTS_TXT"; then       
            chown -R "$user":"$user" "$FUN_FACTS_TXT"
        else
            log "ERROR: Can't download Fun Facts! text file."
        fi
    fi
}


function set_config() {
    sed -i "s|^\($1\s*=\s*\).*|\1\"$2\"|" "$SCRIPT_CFG"
    echo "'$1' set to '$2'."
}


function get_config() {
    if [[ -f "$SCRIPT_CFG" ]]; then
        local config
        config="$(grep -Po "(?<=^$1 = ).*" "$SCRIPT_CFG")"
        config="${config%\"}"
        config="${config#\"}"
        echo "$config"
    else
        return 1
    fi
}


function check_config() {
    CONFIG_FLAG=1

    #~ echo "Checking config file ..."

    SPLASH_PATH="$(get_config "splashscreen_path")"
    TEXT_COLOR="$(get_config "text_color")"
    BOOT_SCRIPT="$(get_config "boot_script")"
    LOG="$(get_config "log")"

    validate_splash "$SPLASH_PATH" || exit 1
    validate_color "$TEXT_COLOR" || exit 1
    validate_true_false "boot_script" "$BOOT_SCRIPT" || exit 1
    validate_true_false "log" "$LOG" || exit 1

    #~ echo "Checking config file ... OK"

    #~ echo "Setting config file ..."

    if [[ -z "$SPLASH_PATH" ]]; then
        SPLASH_PATH="$DEFAULT_SPLASH"
        echo "'splashscreen_path' not set. Switching to defaults ..."
        set_config "splashscreen_path" "$SPLASH_PATH"
    fi

    if [[ -z "$TEXT_COLOR" ]]; then
        TEXT_COLOR="$DEFAULT_COLOR"
        echo "'text_color' not set. Switching to defaults ..."
        set_config "text_color" "$TEXT_COLOR"
    fi

    if [[ -z "$BOOT_SCRIPT" ]]; then
        BOOT_SCRIPT="$DEFAULT_BOOT_SCRIPT"
        echo "'boot_script' not set. Switching to defaults ..."
        set_config "boot_script" "$BOOT_SCRIPT"
    fi

    if [[ -z "$LOG" ]]; then
        LOG="$DEFAULT_LOG"
        echo "'log' not set. Switching to defaults ..."
        set_config "log" "$LOG"
    fi

    #~ echo "Setting config file ... OK"

    #~ echo "Config file"
    #~ echo "-----------"
    #~ echo "'splashscreen_path'   = '$SPLASH_PATH'"
    #~ echo "'text_color'          = '$TEXT_COLOR'"
    #~ echo "'boot_script'         = '$BOOT_SCRIPT'"
    #~ echo "'log'                 = '$LOG'"
}


function edit_config() {
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        local config_file
        config_file="$(dialog \
                    --backtitle "$SCRIPT_TILE" \
                    --title "Config file" \
                    --editbox "$SCRIPT_CFG" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
        local result_value
        result_value="$?"
        if [[ "$result_value" == "$DIALOG_OK" ]]; then
            echo "$config_file" > "$SCRIPT_CFG" \
            && dialog \
                    --backtitle "$SCRIPT_TITLE" \
                    --title "Info" \
                    --msgbox "Config file updated." 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
        fi
    else
        nano "$SCRIPT_CFG"
    fi
}


function reset_config() {
    # TODO: Create a function to select all keys dynamically.
    set_config "splashscreen_path" ""
    set_config "text_color" ""
    set_config "boot_script" ""
    set_config "log" ""
}


function usage() {
    echo
    echo "USAGE: sudo $0 [OPTIONS]"
    echo
    echo "Use 'sudo $0 --help' to see all the options."
}


function enable_boot_script() {
    local command="\"$SCRIPT_FULL\" --create-fun-fact \&"
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


function assure_safe_exit_boot_script() {
    grep -q '^exit 0$' "$RCLOCAL" || echo "exit 0" >> "$RCLOCAL"
}


function check_boot_script() {
    grep -q "$SCRIPT_DIR" "$RCLOCAL"
}


function check_apply_splash() {
    if [[ ! -f "$SPLASH_LIST" ]]; then
        touch "$SPLASH_LIST"
        chown -R "$user":"$user" "$SPLASH_LIST"
    fi
    if [[ ! -f "$RESULT_SPLASH" ]]; then
        is_splash_applied && echo "" > "$SPLASH_LIST"
        local error_message="Create a Fun Facts! splashscreen before applying it."
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            log "$error_message" > /dev/null
            dialog \
                --backtitle "$SCRIPT_TITLE" \
                --title "Error!" \
                --msgbox "$error_message" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
            return 1
        else
            log "ERROR: $error_message"
            echo "Try 'sudo $0 --help' for more info." >&2
            exit 1
        fi
    fi
}

function is_splash_applied() {
    grep -q "$RESULT_SPLASH" "$SPLASH_LIST"
}


function apply_splash() {
    if check_apply_splash; then
        if is_splash_applied; then
            local info_message="Fun Facts! splashscreen is already applied."
            if [[ "$GUI_FLAG" -eq 1 ]]; then
                dialog \
                    --backtitle "$SCRIPT_TITLE" \
                    --title "Info" \
                    --msgbox "$info_message" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
            else
                log "$info_message"
            fi
       else
            echo "$RESULT_SPLASH" > "$SPLASH_LIST"
            local success_message="Fun Facts! splashscreen applied succesfully!"
            if [[ "$GUI_FLAG" -eq 1 ]]; then
                dialog \
                    --backtitle "$SCRIPT_TITLE" \
                    --title "Success!" \
                    --msgbox "$success_message" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
            else
                echo "$success_message"
            fi
        fi
    fi
}


function get_current_theme() {
    sed -n "/name=\"ThemeSet\"/ s/^.*value=['\"]\(.*\)['\"].*/\1/p" "$home/.emulationstation/es_settings.cfg"
}


function get_font() {
    local theme
    theme="$(get_current_theme)"

    [[ -z "$theme" ]] && theme="carbon"

    local font
    font="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed')]/textlist/fontPath" \
        "$ES_THEMES_DIR/$theme/$theme.xml" 2> /dev/null)"

    if [[ -n "$font" ]]; then
        font="$ES_THEMES_DIR/$theme/$font"
    else
        # note: the find below returns the full path file name.
        font="$(find "$ES_THEMES_DIR/$theme/" -type f -name '*.ttf' -print -quit)"
        if [[ -z "$font" ]]; then
            log "ERROR: Unable to get the font from the '$theme' theme files."
            echo "Aborting ..." >&2
            exit 1
        fi
    fi
    echo "$font"
}


function create_fun_fact() {
    local splash
    splash="$(get_config "splashscreen_path")"
    local color
    color="$(get_config "text_color")"
    local font
    font="$(get_font)"
    local random_fact
    random_fact="$(shuf -n 1 "$FUN_FACTS_TXT")"

    if [[ "$GUI_FLAG" -eq 1 ]]; then
        dialog \
            --backtitle "$SCRIPT_TITLE" \
            --infobox "Creating Fun Facts! splashscreen ..." 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
    else
        echo "Creating Fun Facts! splashscreen ..."
    fi

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
    && [[ "$GUI_FLAG" -eq 1 ]] && dialog --backtitle "$SCRIPT_TITLE" --title "Success!" --msgbox "Fun Facts! splashscreen successfully created!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty || echo "Fun Facts! splashscreen successfully created!"
}


function select_fun_facts() {
    local fun_facts=()
    local fun_facts_total
    local options
    local start="$1"
    local items="$2"
    local next="--> NEXT -->"
    local prev="<-- PREVIOUS <--"
    local quit="--> QUIT <--"
    [[ -z "$breaks" ]] && local breaks=1

    clear

    while IFS= read -r line; do
        #~ fun_facts+=("${line//$'\n\r'}")
        fun_facts+=("${line}")
    done < "$FUN_FACTS_TXT"

    fun_facts_total="${#fun_facts[@]}"

    options=("${fun_facts[@]:$start:$items}" "$quit")

    if (( "$fun_facts_total" > (( "$start" + "$items" )) &&  "$start" == 0 )); then
        options=("${fun_facts[@]:$start:$items}" "$next" "$quit")
    elif (( "$fun_facts_total" < (( "$start" + "$items" )) &&  "$start" != 0 )); then
        options=("${fun_facts[@]:$start:$items}" "$prev" "$quit")
    elif (( "$start" >= "$items" )); then
        options=("${fun_facts[@]:$start:$items}" "$prev" "$next" "$quit")
    fi

    echo "Choose a Fun Fact! to remove"
    echo "----------------------------"
    select option in "${options[@]}"; do
        case "$option" in
            "$option" )
                if [[ "$option" == "$next" ]]; then
                    ((breaks++))
                    start=$((start + items))
                    select_fun_facts "$start" "$items"
                elif  [[ "$option" == "$prev" ]]; then
                    ((breaks++))
                    start=$((start - items))
                    select_fun_facts "$start" "$items"
                elif [[ "$option" == "$quit" ]]; then
                    exit
                else
                    if [[ -z "$option" ]]; then
                        echo "Invalid option. Select a number between 1 and ${#options[@]}."
                    else
                        break "$breaks"
                    fi
                fi
                ;;
        esac
    done
}


function is_fun_facts_empty() {
    if [[ ! -s "$FUN_FACTS_TXT" ]]; then
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            log "'$FUN_FACTS_TXT' is empty!"
            return 1
        else
            log "'$FUN_FACTS_TXT' is empty!"
            exit 1
        fi
    else
        return 0
    fi
}


function add_fun_fact() {
    while IFS= read -r line; do
        if [[ "$1" == "$line" ]]; then
            if [[ "$GUI_FLAG" -eq 1 ]]; then
                log "'$1' is already in '$FUN_FACTS_TXT'"
                return 1
            else
                log "ERROR: '$1' is already in '$FUN_FACTS_TXT'"
                exit 1
            fi
        fi
    done < "$FUN_FACTS_TXT"
    echo "$1" >> "$FUN_FACTS_TXT" && echo "'$1' Fun Fact! added succesfully!"
}


function remove_fun_fact() {
    is_fun_facts_empty
    if [[ -n "$1" ]]; then
        sed -i "/^$1$/ d" "$FUN_FACTS_TXT"
    else
        select_fun_facts 0 5
        sed -i "/^$option$/ d" "$FUN_FACTS_TXT" # $option comes from select_fun_facts()
        echo "'$option' removed successfully!" && sleep 0.5
        remove_fun_fact
    fi
}


function validate_splash() {
    [[ -z "$1" ]] && return 0

    if [[ ! -f "$1" ]]; then
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            local error_message="Can't set/get splashscreen path. '$1' file not found!"
        else
            local error_message="ERROR: Can't set/get splashscreen path. '$1' file not found!"
        fi
        log "$error_message"
        [[ "$CONFIG_FLAG" -eq 1 ]] && log "Check the 'splashscreen_path' value in '$SCRIPT_CFG'"
        return 1
    fi
}


function validate_color() {
    [[ -z "$1" ]] && return 0
    if convert -list color | grep -q "^$1\b"; then
        return 0
    else
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            log "Can't set/get text color. Invalid color '$1'."
            [[ "$CONFIG_FLAG" -eq 1 ]] && log "Check the 'text_color' value in '$SCRIPT_CFG'"
        else
            log "ERROR: Can't set/get text color. Invalid color '$1'."
            [[ "$CONFIG_FLAG" -eq 1 ]] && log "Check the 'text_color' value in '$SCRIPT_CFG'"
            echo >&2
            echo "Short list of available colors:" >&2
            echo "-------------------------------" >&2
            echo "black white gray gray10 gray25 gray50 gray75 gray90" >&2
            echo "pink red orange yellow green silver blue cyan purple brown" >&2
            echo >&2
            echo "TIP: run the 'convert -list color' command to get a full list." >&2
        fi
        return 1
    fi
}

function validate_true_false() {
    [[ -z "$2" ]] && return 0
    if [[ "$2" != "false" && "$2" != "true" ]]; then
        log "ERROR: Can't enable/disable $1. Invalid boolean '$2'"
        [[ "$CONFIG_FLAG" -eq 1 ]] && log "Check the '$1' value in '$SCRIPT_CFG'"
        return 1
    fi
}


function check_updates() {
    [[ "$GUI_FLAG" -eq 0 ]] && echo "Let's see if there are any updates ..."
    cd "$SCRIPT_DIR"
    git remote update > /dev/null
    UPSTREAM="$1@{u}"
    LOCAL="$(git rev-parse @)"
    REMOTE="$(git rev-parse $UPSTREAM)"
    BASE="$(git merge-base @ $UPSTREAM)"
    if [[ "$LOCAL" == "$REMOTE" ]]; then
        updates_status="up-to-date"
        updates_output="up to date"
    elif [[ "$LOCAL" == "$BASE" ]]; then
        updates_status="needs-to-pull"
        updates_output="there are updates"
    elif [[ "$REMOTE" == "$BASE" ]]; then
        updates_status="needs-to-push"
        updates_output="did you make any changes??"
    else
        updates_status="diverged"
        updates_output="diverged"
    fi
    cd "$OLDPWD"
    [[ "$GUI_FLAG" -eq 0 ]] && echo "${updates_output^}"
}


function get_last_commit() {
    echo "$(git -C "$SCRIPT_DIR" log -1 --pretty=format:"%cr (%h)")"
}


function gui() {
    GUI_FLAG=1
    while true; do
        check_config #> /dev/null

        version="$SCRIPT_VERSION"

        if is_splash_applied; then
            option_apply_splash="Apply Fun Facts! splashscreen (already applied)"
        else
            option_apply_splash="Apply Fun Facts! splashscreen"
        fi

        check_boot_script
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            option_boot="enabled"
        else
            option_boot="disabled"
        fi

        if [[ "$SCRIPT_DIR" == "$SCRIPTMODULE_DIR" ]]; then # If script is used as a scriptmodule
            option_updates="Update script"
        else
            check_updates
            option_updates="Update script ($updates_output)"
        fi

        options=(
            1 "Set splashscreen path ($(get_config "splashscreen_path"))"
            2 "Set text color ($(get_config "text_color"))"
            3 "Add a new Fun Fact!"
            4 "Remove Fun Facts!"
            5 "Create a new Fun Facts! splashscreen"
            6 "$option_apply_splash"
            7 "Enable/Disable script at boot ($option_boot)"
            8 "Edit config file"
            9 "Reset config file"
            10 "$option_updates"
        )

        menu_items="${#options[@]}"
        
        if [[ "$SCRIPT_DIR" == "$SCRIPTMODULE_DIR" ]]; then # If script is used as a scriptmodule
            menu_text="Version: $version"
        else
            last_commit="$(get_last_commit)"
            menu_text="Version: $version\nLast commit: $last_commit"
        fi
        
        cmd=(dialog \
            --backtitle "$SCRIPT_TITLE"
            --title "Fun Facts! Splashscreens" \
            --cancel-label "Exit" \
            --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")

        choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    CONFIG_FLAG=0

                    splash="$(dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --title "Set splashscreen path" \
                        --cancel-label "Back" \
                        --inputbox "Enter path to splashscreen.\n\n(If input is left empty, default splashscreen will be used)" \
                            12 "$DIALOG_WIDTH" 2>&1 >/dev/tty)"

                    result_value="$?"
                    if [[ "$result_value" == "$DIALOG_OK" ]]; then
                        validation="$(validate_splash "$splash")"
                        if [[ -n "$validation" ]]; then
                            dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --title "Error!" \
                                --msgbox "$validation" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        else
                            if [[ -z "$splash" ]]; then
                                SPLASH_PATH="$DEFAULT_SPLASH"
                            else
                                SPLASH_PATH="$splash"
                            fi
                            set_config "splashscreen_path" "$SPLASH_PATH" > /dev/null
                            dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --title "Success!" \
                                --msgbox "'splashscreen_path' set to '$SPLASH_PATH'" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                2)
                    CONFIG_FLAG=0

                    cmd=(dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --title "Set text color" \
                        --cancel-label "Back" \
                        --menu "Choose an option" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")

                    options=(
                        1 "Basic colors"
                        2 "Full list of colors"
                    )

                    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

                    if [[ -n "$choice" ]]; then
                        case "$choice" in
                            1)
                                local i=1
                                local color_list=(
                                    "white (default)"
                                    "black"
                                    "gray"
                                    "gray10"
                                    "gray25"
                                    "gray50"
                                    "gray75"
                                    "gray90"
                                    "pink"
                                    "red"
                                    "orange"
                                    "yellow"
                                    "green"
                                    "silver"
                                    "blue"
                                    "cyan"
                                    "purple"
                                    "brown"
                                )

                                options=()

                                for color in "${color_list[@]}"; do
                                    options+=("$i" "$color")
                                    ((i++))
                                done

                                cmd=(dialog \
                                    --backtitle "$SCRIPT_TITLE" \
                                    --title "Set text color" \
                                    --cancel-label "Back" \
                                    --menu "Choose a color" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "${#color_list[@]}")

                                choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
                                result_value="$?"
                                if [[ "$result_value" == "$DIALOG_OK" ]]; then
                                    if [[ "$choice" -eq 1 ]]; then
                                        local color=""
                                    else
                                        local color="${options[$((choice*2-1))]}"
                                    fi

                                    local validation="$(validate_color "$color")"

                                     if [[ -n "$validation" ]]; then
                                        dialog \
                                            --backtitle "$SCRIPT_TITLE" \
                                            --title "Error!" \
                                            --msgbox "$validation" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                                    else
                                        if [[ -z "$color" ]]; then
                                            TEXT_COLOR="$DEFAULT_COLOR"
                                        else
                                            TEXT_COLOR="$color"
                                        fi
                                        set_config "text_color" "$TEXT_COLOR" > /dev/null
                                        dialog \
                                            --backtitle "$SCRIPT_TITLE" \
                                            --title "Success!" \
                                            --msgbox "Text color set to '$TEXT_COLOR'" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                                    fi
                                fi
                                ;;
                            2)
                                local i=1
                                local color_list=()
                                options=()

                                while IFS= read -r line; do
                                    color_list+=("$line")
                                done < <(convert -list color | grep "srgb" | grep -Eo "^[^ ]+")

                                for color in "${color_list[@]}"; do
                                    options+=("$i" "$color")
                                    ((i++))
                                done

                                cmd=(dialog \
                                    --backtitle "$SCRIPT_TITLE" \
                                    --title "Set text color" \
                                    --cancel-label "Back" \
                                    --menu "Choose a color" 15 60 "${#color_list[@]}")

                                choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
                                result_value="$?"
                                if [[ "$result_value" == "$DIALOG_OK" ]]; then
                                    local color="${options[$((choice*2-1))]}"

                                    local validation="$(validate_color $color)"

                                     if [[ -n "$validation" ]]; then
                                        dialog \
                                            --backtitle "$SCRIPT_TITLE" \
                                            --title "Error!" \
                                            --msgbox "$validation" 0 0 2>&1 >/dev/tty
                                    else
                                        if [[ -z "$color" ]]; then
                                            TEXT_COLOR="$DEFAULT_COLOR"
                                        else
                                            TEXT_COLOR="$color"
                                        fi
                                        set_config "text_color" "$TEXT_COLOR" > /dev/null
                                        dialog \
                                            --backtitle "$SCRIPT_TITLE" \
                                            --title "Success!" \
                                            --msgbox "Text color set to '$TEXT_COLOR'" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                                    fi
                                fi
                                ;;
                        esac
                    fi
                    ;;
                3)
                    new_fun_fact="$(dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --title "Add a new Fun Fact!" \
                        --cancel-label "Back" \
                        --inputbox "Enter a new Fun Fact!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty)"

                    result_value="$?"
                    if [[ "$result_value" == "$DIALOG_OK" ]]; then
                        local validation
                        validation="$(add_fun_fact "$new_fun_fact")"
                        return_value="$?"
                        if [[ "$return_value" -eq 0 ]]; then
                            dialog_title="Success!"
                        else
                            dialog_title="Error!"
                        fi
                        if [[ -n "$validation" ]]; then
                            dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --title "$dialog_title" \
                                --msgbox "$validation" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                4)
                    while true; do
                        local validation
                        validation="$(is_fun_facts_empty)"
                        if [[ -n "$validation" ]]; then
                            dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --title "Error!" \
                                --msgbox "$validation" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        else
                            local fun_facts=()
                            local fun_fact
                            local options=()
                            local i=1

                            while IFS= read -r line; do
                                #~ fun_facts+=("${line//$'\n\r'}")
                                fun_facts+=("${line}")
                            done < "$FUN_FACTS_TXT"

                            for fun_fact in "${fun_facts[@]}"; do
                                options+=("$i" "$fun_fact")
                                ((i++))
                            done

                            cmd=(dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --title "Remove a Fun Fact!" \
                                --cancel-label "Back" \
                                --menu "Choose a Fun Fact! to remove" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "${#fun_facts[@]}")

                            choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

                            if [[ -n "$choice" ]]; then
                                local fun_fact
                                fun_fact="${options[$((choice*2-1))]}"
                                remove_fun_fact "$fun_fact" \
                                && dialog \
                                    --backtitle "$SCRIPT_TITLE" \
                                    --title "Success!" \
                                    --msgbox "'$fun_fact' succesfully removed!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                            else
                                break
                            fi
                        fi
                    done
                    ;;
                5)
                    local validation
                    validation="$(is_fun_facts_empty)"
                    if [[ -n "$validation" ]]; then
                        dialog \
                            --backtitle "$SCRIPT_TITLE" \
                            --title "Error!" \
                            --msgbox "$validation" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                    else
                        create_fun_fact
                    fi
                    ;;
                6)
                    apply_splash
                    ;;
                7)
                    check_boot_script
                    local return_value="$?"
                    if [[ "$return_value" -eq 0 ]]; then
                        if disable_boot_script; then
                            set_config "boot_script" "false" > /dev/null
                            local output="Script DISABLED at boot."
                            local dialog_title="Success!"
                         else
                            local output="Failed to DISABLE script at boot."
                            local dialog_title="Error!"
                        fi
                    else
                        if enable_boot_script; then
                            set_config "boot_script" "true" > /dev/null
                            local output="Script ENABLED at boot."
                            local dialog_title="Success!"
                         else
                            local output="Failed to ENABLE script at boot."
                            local dialog_title="Error!"
                        fi
                    fi
                    dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --title "$dialog_title" \
                        --msgbox "$output" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                    ;;
                8)
                    edit_config
                    ;;
                9)
                    reset_config
                    ;;
                10)
                    if [[ "$SCRIPT_DIR" == "$SCRIPTMODULE_DIR" ]]; then # If script is used as a scriptmodule
                        local text="Can't update the script when using it from RetroPie-Setup."
                                text+="\n\nGo to:"
                                text+="\n -> Manage packages"
                                text+="\n -> Manage experimental packages"
                                text+="\n -> fun-facts-splashscreens"
                                text+="\n -> Update from source"
                                 
                        dialog \
                            --backtitle "$SCRIPT_TITLE" \
                            --title "Info" \
                            --msgbox "$text" 15 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                    else
                        if [[ "$updates_status" == "needs-to-pull" ]]; then
                            git pull && chown -R "$user":"$user" .
                        else
                            dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --title "Info" \
                                --msgbox "Fun Facts! Splashscreens is $updates_output!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
            esac
        else
            break
        fi
    done
}


function get_options() {
    if [[ -z "$1" ]]; then
        usage
        exit 0
    fi
    
    OPTION="$1"
    
    while [[ -n "$1" ]]; do
        case "$1" in
#H --help                                   Print the help message and exit.
            --help)
                echo
                echo "$SCRIPT_TITLE"
                for ((i=1; i<="${#SCRIPT_TITLE}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
                echo "$SCRIPT_DESCRIPTION"
                echo
                echo
                echo "USAGE: sudo $0 [OPTIONS]"
                echo
                echo "OPTIONS:"
                echo
                sed '/^#H /!d; s/^#H //' "$0"
                echo
                exit 0
                ;;
#H --splash-path [path/to/splashscreen]     Set the image to use as Fun Facts! splashscreen.
            --splash-path)
                check_argument "$1" "$2" || exit 1
                shift
                validate_splash "$1" || exit 1
                set_config "splashscreen_path" "$1"
                ;;
#H --text-color [color]                     Set the text color to use on the Fun Facts! splashscreen.
            --text-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_color "$1" || exit 1
                set_config "text_color" "$1"
                ;;
#H --add-fun-fact [text]                    Add new Fun Facts!.
            --add-fun-fact)
                check_argument "$1" "$2" || exit 1
                shift
                add_fun_fact "$1"
                ;;
#H --remove-fun-fact                        Remove Fun Facts!.
            --remove-fun-fact)
                remove_fun_fact
                ;;
#H --create-fun-fact                        Create a new Fun Facts! splashscreen.
            --create-fun-fact)
                check_config #> /dev/null
                is_fun_facts_empty
                create_fun_fact
                ;;
#H --apply-splash                           Apply the Fun Facts! splashscreen.
            --apply-splash)
                apply_splash
                ;;
#H --enable-boot                            Enable script at boot.
            --enable-boot)
                if enable_boot_script; then
                    set_config "boot_script" "true" > /dev/null
                    echo "Script ENABLED at boot."
                else
                    log "ERROR: failed to ENABLE script at boot."
                fi
                ;;
#H --disable-boot                           Disable script at boot.
            --disable-boot)
                if disable_boot_script; then
                    set_config "boot_script" "false" > /dev/null
                    echo "Script DISABLED at boot."
                else
                    log "ERROR: failed to DISABLE script at boot."
                fi
                ;;
#H --gui                                    Start GUI.
            --gui)
                gui
                ;;
#H --edit-config                            Edit config file.
            --edit-config)
                edit_config
                ;;
#H --reset-config                           Reset config file.
            --reset-config)
                reset_config
                ;;
#H --update                                 Update script.
            --update)
                check_updates
                if [[ "$updates_status" == "needs-to-pull" ]]; then
                    git pull && chown -R "$user":"$user" .
                fi
                ;;
#H --version                                Show script version.
            --version)
                echo "$SCRIPT_VERSION"
                ;;
#H --enable-log                             Enable logging.
            --enable-log)
                set_config "log" "true"
                ;;
#H --disable-log                            Disable logging.
            --disable-log)
                set_config "log" "false"
                ;;
            *)
                log "ERROR: Invalid option '$1'" >&2
                echo "Try 'sudo $0 --help' for more info." >&2
                exit 2
                ;;
        esac
        shift
    done
}

function main() {
    if ! is_sudo; then
        log "ERROR: Script must be run under sudo."
        usage
        exit 1
    fi
        
    if ! is_retropie; then
        log "ERROR: RetroPie is not installed. Aborting ..."
        exit 1
    fi

    check_dependencies
    
    check_log="$(get_config "log")"
    if [[ "$check_log" == "" ]]; then
        LOG="true"
    fi
    
    check_boot="$(get_config "boot_script")"
    if [[ "$check_boot" == "false" || "$check_boot" == "" ]]; then
        disable_boot_script
    elif [[ "$check_boot" == "true" ]]; then
        enable_boot_script
    fi
    
    check_default_files

    mkdir -p "$RP_DIR/splashscreens"

    chown -R "$user":"$user" .

    get_options "$@"
}

main "$@"
