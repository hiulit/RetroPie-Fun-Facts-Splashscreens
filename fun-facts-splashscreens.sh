#!/usr/bin/env bash
# fun-facts-splashscreens.sh
#
# Fun Facts! Splashscreens for RetroPie.
# A tool for RetroPie to generate splashscreens with random video game related Fun Facts!.
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
readonly RP_CONFIG_DIR="/opt/retropie/configs"
readonly RP_ROMS_DIR="$RP_DIR/roms"
readonly ES_THEMES_DIR="/etc/emulationstation/themes"
readonly SPLASH_LIST="/etc/splashscreen.list"
readonly RCLOCAL="/etc/rc.local"
readonly DEPENDENCIES=("imagemagick" "librsvg2-bin")
readonly TMP_DIR="$home/tmp"

readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_CFG="$SCRIPT_DIR/fun-facts-splashscreens-settings.cfg"
readonly SCRIPT_TITLE="Fun Facts! Splashscreens for RetroPie"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to generate splashscreens with random video game related Fun Facts!."
readonly SCRIPTMODULE_DIR="/opt/retropie/supplementary/fun-facts-splashscreens"
readonly SCRIPT_RUNCOMMAND_ONEND="$SCRIPT_DIR/fun-facts-splashscreens-runcommand-onend.sh"


# Variables ############################################

# Files
readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun-facts.txt"
readonly RESULT_SPLASH="$RP_DIR/splashscreens/fun-facts-splashscreen.png"
readonly LOG_FILE="$SCRIPT_DIR/fun-facts-splashscreens.log"
readonly RUNCOMMAND_ONEND="$RP_CONFIG_DIR/all/runcommand-onend.sh"

# Defaults
readonly DEFAULT_SPLASH="$SCRIPT_DIR/retropie-default.png"
readonly DEFAULT_COLOR="white"
readonly DEFAULT_BG_COLOR="black"
readonly DEFAULT_BOOT_SCRIPT="false"
readonly DEFAULT_LOG="false"

# Dialogs
readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_ESC=255
readonly DIALOG_HEIGHT=20
readonly DIALOG_WIDTH=60
readonly DIALOG_BACKTITLE="$SCRIPT_TITLE"

# Flags
GUI_FLAG=0
CONFIG_FLAG=0

# Global variables
SPLASH_PATH=
TEXT_COLOR=
BG_COLOR=
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


function is_arm() {
    uname -m | grep -q "arm"
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
        if ! dpkg-query -W -f='${Status}' "$pkg" | awk '{print $3}' | grep -q "^installed$"; then
        #~ if ! dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" > /dev/null; then
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


function download_default_splash() {
    if curl -s -f "https://raw.githubusercontent.com/RetroPie/retropie-splashscreens/master/retropie-default.png" -o "$DEFAULT_SPLASH"; then
        chown -R "$user":"$user" "$DEFAULT_SPLASH"
    else
        log "ERROR: Can't download default splashscreen."
        return 1
    fi
}


function download_config_file() {
    if curl -s -f  "https://raw.githubusercontent.com/hiulit/RetroPie-Fun-Facts-Splashscreens/master/fun-facts-splashscreens-settings.cfg" -o "$SCRIPT_CFG"; then
        chown -R "$user":"$user" "$SCRIPT_CFG"
    else
        log "ERROR: Can't download config file."
        return 1
    fi
}


function download_fun_facts() {
    if curl -s -f  "https://raw.githubusercontent.com/hiulit/RetroPie-Fun-Facts-Splashscreens/master/fun-facts.txt" -o "$FUN_FACTS_TXT"; then
        chown -R "$user":"$user" "$FUN_FACTS_TXT"
    else
        log "ERROR: Can't download Fun Facts! text file."
        return 1
    fi
}


function restore_default_files() {
    download_default_splash || return 1
    download_config_file || return 1
    download_fun_facts || return 1
}


function check_default_files() {
    [[ ! -f "$DEFAULT_SPLASH" ]] && download_default_splash
    [[ ! -f "$SCRIPT_CFG" ]] && download_config_file
    [[ ! -f "$FUN_FACTS_TXT" ]] && download_fun_facts
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

    SPLASH_PATH="$(get_config "splashscreen_path")"
    TEXT_COLOR="$(get_config "text_color")"
    BG_COLOR="$(get_config "bg_color")"
    BOOT_SCRIPT="$(get_config "boot_script")"
    LOG="$(get_config "log")"

    validate_splash "$SPLASH_PATH" || exit 1
    validate_color "$TEXT_COLOR" || exit 1
    validate_color "$BG_COLOR" || exit 1
    validate_true_false "boot_script" "$BOOT_SCRIPT" || exit 1
    validate_true_false "log" "$LOG" || exit 1

    if [[ -z "$SPLASH_PATH" ]]; then
        SPLASH_PATH="$DEFAULT_SPLASH"
        set_config "splashscreen_path" "$SPLASH_PATH" > /dev/null
    fi

    if [[ -z "$TEXT_COLOR" ]]; then
        TEXT_COLOR="$DEFAULT_COLOR"
        set_config "text_color" "$TEXT_COLOR" > /dev/null
    fi
    
    if [[ -z "$BG_COLOR" ]]; then
        BG_COLOR="$DEFAULT_BG_COLOR"
        set_config "bg_color" "$BG_COLOR" > /dev/null
    fi

    if [[ -z "$BOOT_SCRIPT" ]]; then
        BOOT_SCRIPT="$DEFAULT_BOOT_SCRIPT"
        set_config "boot_script" "$BOOT_SCRIPT" > /dev/null
    fi

    if [[ -z "$LOG" ]]; then
        LOG="$DEFAULT_LOG"
        set_config "log" "$LOG" > /dev/null
    fi
}


function edit_config() {
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        local config_file
        config_file="$(dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
                    --title "Config file" \
                    --ok-label "Save" \
                    --cancel-label "Back" \
                    --editbox "$SCRIPT_CFG" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
        local result_value="$?"
        if [[ "$result_value" == "$DIALOG_OK" ]]; then
            echo "$config_file" > "$SCRIPT_CFG" \
            && dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
                    --title "Info" \
                    --msgbox "Config file updated." 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
        fi
    else
        nano "$SCRIPT_CFG"
    fi
}


function reset_config() {
    while read line; do
        set_config "$line" ""
    done < <(grep -Po ".*?(?=\ = )" "$SCRIPT_CFG")
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
    local return_value="$?"
    [[ "$return_value" -eq 0 ]] || return 1
    assure_safe_exit_boot_script
    check_boot_script
}


function disable_boot_script() {
    sed -i "/$(basename "$0")/d" "$RCLOCAL"
    local return_value="$?"
    [[ "$return_value" -eq 0 ]] || return 1
    assure_safe_exit_boot_script
    ! check_boot_script
}


function assure_safe_exit_boot_script() {
    grep -q '^exit 0$' "$RCLOCAL" || echo "exit 0" >> "$RCLOCAL"
}


function check_boot_script() {
    grep -q "$SCRIPT_DIR" "$RCLOCAL"
}


function enable_runcommand_onend() {
    if [[ ! -f "$RUNCOMMAND_ONEND" ]]; then
        touch "$RUNCOMMAND_ONEND"
        cat > "$RUNCOMMAND_ONEND" << _EOF_
#!/usr/bin/env bash
# $(basename "$RUNCOMMAND_ONEND")

_EOF_
        chown -R "$user":"$user" "$RUNCOMMAND_ONEND"
    fi
    local command="\"$SCRIPT_RUNCOMMAND_ONEND\" \"\$1\" \"\$2\" \"\$3\" \"\$4\""
    disable_runcommand_onend # deleting any previous config (do nothing if there isn't).
    sed -i "\$a$command" "$RUNCOMMAND_ONEND"
    local return_value="$?"
    [[ "$return_value" -eq 0 ]] || return 1
    check_runcommand_onend
}


function disable_runcommand_onend() {
    sed -i "/[^# ]$(basename "$SCRIPT_RUNCOMMAND_ONEND")/d" "$RUNCOMMAND_ONEND"
    local return_value="$?"
    [[ "$return_value" -eq 0 ]] || return 1
    ! check_runcommand_onend
}


function check_runcommand_onend() {
    grep -q "$SCRIPT_RUNCOMMAND_ONEND" "$RUNCOMMAND_ONEND"
}


function check_apply_splash() {
    if [[ ! -f "$SPLASH_LIST" ]]; then
        touch "$SPLASH_LIST"
        chown -R "$user":"$user" "$SPLASH_LIST"
    fi
    if [[ ! -f "$RESULT_SPLASH" ]]; then
        is_splash_applied && echo "" > "$SPLASH_LIST"
        local error_message="Create a Fun Facts! Splashscreen before applying it."
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            log "$error_message" > /dev/null
            dialog \
                --backtitle "$DIALOG_BACKTITLE" \
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
            local info_message="Fun Facts! Splashscreen is already applied."
            if [[ "$GUI_FLAG" -eq 1 ]]; then
                dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
                    --title "Info" \
                    --msgbox "$info_message" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
            else
                log "$info_message"
            fi
       else
            echo "$RESULT_SPLASH" > "$SPLASH_LIST"
            local success_message="Fun Facts! Splashscreen applied succesfully!"
            if [[ "$GUI_FLAG" -eq 1 ]]; then
                dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
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


function get_screen_resolution_x() {
    if is_arm; then
        local screen_resolution="$(fbset -s | grep -o -P '(?<=").*(?=")')"
        echo "$screen_resolution" | cut -dx -f1
    else
        xdpyinfo | awk -F '[ x]+' '/dimensions:/{print $3}'
    fi
}


function get_screen_resolution_y() {
    if is_arm; then
        local screen_resolution="$(fbset -s | grep -o -P '(?<=").*(?=")')"
        echo "$screen_resolution" | cut -dx -f2
    else
        xdpyinfo | awk -F '[ x]+' '/dimensions:/{print $4}'
    fi
}

function get_system_logo() {
    local logo
    logo="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed') or contains(@name,'system')]/image[@name='logo']/path" \
        "$ES_THEMES_DIR/$theme/$system/theme.xml" 2> /dev/null | head -1)"
    logo="$ES_THEMES_DIR/$theme/$system/$logo"
    echo "$logo"
}

function get_boxart() {
    local rom_path="$1"
    [[ -z "$rom_path" ]]  && return 1
    [[ ! -f "$rom_path" ]] && return 1
    rom_path="$(basename "$rom_path")"
    local boxart
    boxart="$(xmlstarlet sel -t -v \
        "/gameList/game[path=\"./$rom_path\"]/image" \
        "$RP_ROMS_DIR/$system/gamelist.xml" 2> /dev/null | head -1)"
    boxart="$RP_ROMS_DIR/$system/$boxart"
    echo "$boxart"
}


function IM_add_background() {
    convert -size "$screen_w"x"$screen_h" xc:"$bg_color" \
        "$TMP_DIR/launching.png"
        
    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        echo "Background ... added!"
    else
        echo "Background failed!"
    fi
}


function IM_convert_svg_to_png() {
    local logo
    logo="$(get_system_logo)"
    local location="$1"
    if [[ "$location" == "up" ]]; then
        local size_y="$(((screen_h*10/100)))"
    elif [[ "$location" == "center" ]]; then
        local size_y="$(((screen_h*25/100)))"
    else
        log "Location not valid!"
        exit 1
    fi
    convert -background none \
        -gravity center \
        -resize "$(((screen_w*60/100)))"x"$size_y" \
        "$logo" "$TMP_DIR/$system.png"
        
    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        echo "SVG converted to PNG successfully!"
    else
        echo "SVG to PNG conversion failed!"
    fi
}


function IM_add_logo() {
    local logo
    logo="$(get_system_logo)"
    local location="$1"
    if file --mime-type "$logo" | grep -q "svg"; then
        echo "mime type is SVG"
        IM_convert_svg_to_png "$location"
    elif file --mime-type "$logo" | grep -q "png" || file --mime-type "$logo" | grep -q "jpeg"; then
        echo "mime type is PNG or JPEG"
        cp "$logo" "$TMP_DIR/$system.png"
    else
        file --mime-type "$logo" 
        log "File type not recognised."
        exit 1
    fi
    if [[ "$location" == "up" ]]; then
        local gravity="north"
        local offset_y="$(((screen_h*5/100)))"
    elif [[ "$location" == "center" ]]; then
        local gravity="center"
        local image_h
        image_h="$(identify -format "%h" "$logo")"
        local offset_y="-$image_h"
    else
        log "Location not valid!"
        exit 1
    fi
    convert "$TMP_DIR/launching.png" \
        "$TMP_DIR/$system.png" \
        -gravity "$gravity" \
        -geometry +0+"$offset_y" \
        -composite \
        "$TMP_DIR/launching.png"

    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        echo "Logo ... added!"
    else
        echo "Logo failed!"
    fi
}


function IM_add_boxart() {
    local rom_path="$1"
    local boxart
    boxart="$(get_boxart "$rom_path")"
    convert "$TMP_DIR/launching.png" \
        \( "$boxart" -resize x"$(((screen_h*45/100)))" \) \
        -gravity center \
        -geometry +0-"$(((screen_h*(10-(5/2))/100)))" \
        -composite \
        "$TMP_DIR/launching.png"
        
    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        echo "Boxart ... added!"
    else
        echo "Boxart failed!"
    fi
}


function IM_add_fun_fact() {
    convert "$TMP_DIR/launching.png" \
        -size "$(((screen_w*75/100)))"x"$(((screen_h*15/100)))" \
        -background none \
        -fill "$text_color" \
        -interline-spacing 2 \
        -font "$font" \
        caption:"$random_fact" \
        -gravity south \
        -geometry +0+"$(((screen_h*15/100)))" \
        -composite \
        "$TMP_DIR/launching.png"

    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        echo "Fun Fact! ... added!"
    else
        echo "Fun Fact! failed!"
    fi
}


function IM_add_press_button_text() {
    convert "$TMP_DIR/launching.png" \
        -size "$(((screen_w*60/100)))"x"$(((screen_h*5/100)))" \
        -background none \
        -fill "$text_color" \
        -interline-spacing 2 \
        -font "$font" \
        caption:"PRESS A BUTTON TO CONFIGURE LAUNCH OPTIONS" \
        -gravity south \
        -geometry +0+"$(((screen_h*5/100)))" \
        -composite \
        "$TMP_DIR/launching.png"
    
    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        echo "Press button ... added!"
    else
        echo "Press button failed!"
    fi
}


function create_fun_fact_boot() {
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --infobox "Creating Fun Facts! Splashscreen ..." 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
    else
        echo "Creating Fun Facts! Splashscreen ..."
    fi

    convert "$splash" \
        -size 1000x100 \
        -background none \
        -fill "$text_color" \
        -interline-spacing 2 \
        -font "$font" \
        caption:"$random_fact" \
        -gravity south \
        -geometry +0+25 \
        -composite \
        "$RESULT_SPLASH"
    
    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "Success!" \
                --msgbox "Fun Facts! Splashscreen successfully created!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
        else
            echo "Fun Facts! Splashscreen successfully created!"
        fi
    else
        local error_message="Fun Facts! Splashscreen failed!"
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            log "$error_message" > /dev/null
            dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "Error!" \
                --msgbox "$error_message" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
        else
            log "$error_message"
        fi
    fi
}


function create_fun_fact_launching() {
    local system="$1"
    #~ local rom_path="/home/pi/RetroPie/roms/$system/Super Mario World.zip" # TO BE REMOVED!!!
    if [[ "$system" == "all" ]]; then
        local system_dir
        for system_dir in "$RP_CONFIG_DIR/"*; do
            system_dir="$(basename "$system_dir")"
            [[ "$system_dir" != "all" ]] && create_fun_fact_launching "$system_dir"
        done
        exit
    else
        if [[ -z "$2" ]]; then
            local result_splash="$RP_CONFIG_DIR/$system/launching.png"
        else
            local rom_path="$2"
            local result_splash="$RP_ROMS_DIR/$system/images/$(basename "${rom_path%.*}")-launching.png"
        fi
        #~ local splash_w=480
        #~ local splash_h=270
        local screen_w
        screen_w="$(get_screen_resolution_x)"
        local screen_h
        screen_h="$(get_screen_resolution_y)"

        mkdir -p "$TMP_DIR"
        
        IM_add_background
        if get_boxart "$rom_path" > /dev/null; then
            IM_add_logo "up"
            IM_add_boxart "$rom_path"
        else
            IM_add_logo "center"
        fi
        IM_add_fun_fact
        IM_add_press_button_text
        
        [[ -f "$result_splash" ]] && rm "$result_splash"
        mv "$TMP_DIR/launching.png" "$result_splash"
        chown -R "$user":"$user" "$TMP_DIR"
        chown -R "$user":"$user" "$result_splash"
        rm  -r "$TMP_DIR"
    fi
}


function create_fun_fact() {
    local splash
    splash="$(get_config "splashscreen_path")"
    local text_color
    text_color="$(get_config "text_color")"
    local bg_color
    bg_color="$(get_config "bg_color")"
    local font
    font="$(get_font)"
    local theme
    theme="$(get_current_theme)"
    local random_fact
    random_fact="$(shuf -n 1 "$FUN_FACTS_TXT")"
    
    if [[ -z "$1" ]]; then
        create_fun_fact_boot
    else
        create_fun_fact_launching "$@"
    fi
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
            option_apply_splash="Apply Fun Facts! Splashscreen (already applied)"
        else
            option_apply_splash="Apply Fun Facts! Splashscreen"
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

        check_log="$(get_config "log")"
        if [[ "$check_log" == "false" || "$check_log" == "" ]]; then
            option_log="disabled"
        elif [[ "$check_log" == "true" ]]; then
            option_log="enabled"
        fi

        options=(
            1 "Set splashscreen path ($(get_config "splashscreen_path"))"
            2 "Set text color ($(get_config "text_color"))"
            3 "Add a new Fun Fact!"
            4 "Remove Fun Facts!"
            5 "Create a new Fun Facts! Splashscreen"
            6 "$option_apply_splash"
            7 "Enable/Disable script at boot ($option_boot)"
            8 "Edit config file"
            9 "Reset config file"
            10 "$option_updates"
            11 "Enable/Disable logging ($option_log)"
            12 "Restore default files"
        )

        menu_items="${#options[@]}"

        if [[ "$SCRIPT_DIR" == "$SCRIPTMODULE_DIR" ]]; then # If script is used as a scriptmodule
            menu_text="Version: $version"
        else
            last_commit="$(get_last_commit)"
            menu_text="Version: $version\nLast commit: $last_commit"
        fi

        cmd=(dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --title "Fun Facts! Splashscreens" \
            --cancel-label "Exit" \
            --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")

        choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    CONFIG_FLAG=0

                    splash="$(dialog \
                        --backtitle "$DIALOG_BACKTITLE" \
                        --title "Set splashscreen path" \
                        --cancel-label "Back" \
                        --inputbox "Enter splashscreen path.\n\n(If input is left empty, default splashscreen will be used)" \
                            12 "$DIALOG_WIDTH" 2>&1 >/dev/tty)"

                    result_value="$?"
                    if [[ "$result_value" == "$DIALOG_OK" ]]; then
                        validation="$(validate_splash "$splash")"
                        if [[ -n "$validation" ]]; then
                            dialog \
                                --backtitle "$DIALOG_BACKTITLE" \
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
                                --backtitle "$DIALOG_BACKTITLE" \
                                --title "Success!" \
                                --msgbox "'splashscreen_path' set to '$SPLASH_PATH'" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                2)
                    CONFIG_FLAG=0

                    cmd=(dialog \
                        --backtitle "$DIALOG_BACKTITLE" \
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
                                    --backtitle "$DIALOG_BACKTITLE" \
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
                                            --backtitle "$DIALOG_BACKTITLE" \
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
                                            --backtitle "$DIALOG_BACKTITLE" \
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
                                    --backtitle "$DIALOG_BACKTITLE" \
                                    --title "Set text color" \
                                    --cancel-label "Back" \
                                    --menu "Choose a color" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "${#color_list[@]}")

                                choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
                                result_value="$?"
                                if [[ "$result_value" == "$DIALOG_OK" ]]; then
                                    local color="${options[$((choice*2-1))]}"

                                    local validation="$(validate_color $color)"

                                     if [[ -n "$validation" ]]; then
                                        dialog \
                                            --backtitle "$DIALOG_BACKTITLE" \
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
                                            --backtitle "$DIALOG_BACKTITLE" \
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
                        --backtitle "$DIALOG_BACKTITLE" \
                        --title "Add a new Fun Fact!" \
                        --cancel-label "Back" \
                        --inputbox "Enter a new Fun Fact!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty)"

                    result_value="$?"
                    if [[ "$result_value" == "$DIALOG_OK" ]]; then
                        if [[ -z "$new_fun_fact" ]]; then
                            dialog \
                                --backtitle "$DIALOG_BACKTITLE" \
                                --title "Error!" \
                                --msgbox "You must enter a Fun Fact!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        else
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
                                    --backtitle "$DIALOG_BACKTITLE" \
                                    --title "$dialog_title" \
                                    --msgbox "$validation" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                            fi
                        fi
                    fi
                    ;;
                4)
                    while true; do
                        local validation
                        validation="$(is_fun_facts_empty)"
                        if [[ -n "$validation" ]]; then
                            dialog \
                                --backtitle "$DIALOG_BACKTITLE" \
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
                                --backtitle "$DIALOG_BACKTITLE" \
                                --title "Remove a Fun Fact!" \
                                --cancel-label "Back" \
                                --menu "Choose a Fun Fact! to remove" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "${#fun_facts[@]}")

                            choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

                            if [[ -n "$choice" ]]; then
                                local fun_fact
                                fun_fact="${options[$((choice*2-1))]}"
                                if [[ -z "$fun_fact" ]]; then
                                    dialog \
                                        --backtitle "$DIALOG_BACKTITLE" \
                                        --title "Error!" \
                                        --msgbox "Can't remove a ghost Fun Fact!.\nTry removing it manually from '$FUN_FACTS_TXT'." 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                                else
                                    remove_fun_fact "$fun_fact" \
                                    && dialog \
                                        --backtitle "$DIALOG_BACKTITLE" \
                                        --title "Success!" \
                                        --msgbox "'$fun_fact' succesfully removed!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                                fi
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
                            --backtitle "$DIALOG_BACKTITLE" \
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
                         else
                            local output="Failed to DISABLE script at boot."
                            local dialog_title="Error!"
                            dialog \
                                --backtitle "$DIALOG_BACKTITLE" \
                                --title "$dialog_title" \
                                --msgbox "$output" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        fi
                    else
                        if enable_boot_script; then
                            set_config "boot_script" "true" > /dev/null
                         else
                            local output="Failed to DISABLE script at boot."
                            local dialog_title="Error!"
                            dialog \
                                --backtitle "$DIALOG_BACKTITLE" \
                                --title "$dialog_title" \
                                --msgbox "$output" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        fi
                    fi
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
                            --backtitle "$DIALOG_BACKTITLE" \
                            --title "Info" \
                            --msgbox "$text" 15 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                    else
                        if [[ "$updates_status" == "needs-to-pull" ]]; then
                            git pull && chown -R "$user":"$user" .
                        else
                            dialog \
                                --backtitle "$DIALOG_BACKTITLE" \
                                --title "Info" \
                                --msgbox "Fun Facts! Splashscreens is $updates_output!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                11)
                    if [[ "$check_log" == "false" ]]; then
                        set_config "log" "true" > /dev/null
                    else
                        set_config "log" "false" >  /dev/null
                    fi
                    ;;
                12)
                    local validation
                    validation="$(restore_default_files)"
                    if [[ -n "$validation" ]]; then
                        local title="Error!"
                        local text="$validation"
                    else
                        local title="Success!"
                        local text="Default files restored successfully!"
                            text+="\n\n"
                            text+="\n- ./$(basename "$DEFAULT_SPLASH")" \
                            text+="\n- ./$(basename "$SCRIPT_CFG")" \
                            text+="\n- ./$(basename "$FUN_FACTS_TXT")"
                    fi
                    dialog \
                        --backtitle "$DIALOG_BACKTITLE" \
                        --title "$title" \
                        --msgbox "$text" 12 "$DIALOG_WIDTH" 2>&1 >/dev/tty
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
#H --splash-path [path/to/splashscreen]     Set the image to use as Fun Facts! Splashscreen.
            --splash-path)
                check_argument "$1" "$2" || exit 1
                shift
                validate_splash "$1" || exit 1
                set_config "splashscreen_path" "$1"
                ;;
#H --text-color [color]                     Set the text color to use on the Fun Facts! Splashscreen.
            --text-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_color "$1" || exit 1
                set_config "text_color" "$1"
                ;;
#H --bg-color [color]                       Set the background color to use on the Fun Facts! Splashscreen.
            --bg-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_color "$1" || exit 1
                set_config "bg_color" "$1"
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
#H --create-fun-fact                        Create a new Fun Facts! Splashscreen.
            --create-fun-fact)
                check_config #> /dev/null
                is_fun_facts_empty
                if [[ -z "$2" ]]; then
                    create_fun_fact
                else
                    shift
                    create_fun_fact "$@"
                    shift
                fi
                ;;
#H --apply-splash                           Apply the Fun Facts! Splashscreen.
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
#H --enable-runcommand-onend                Enable runcommand-onend.
            --enable-runcommand-onend)
                if enable_runcommand_onend; then
                    set_config "runcommand_onend" "true" > /dev/null
                    echo "runcommand-onend ENABLED."
                else
                    log "ERROR: failed to ENABLE runcommand-onend."
                fi
                ;;
#H --disable-runcommand-onend               Disable runcommand-onend.
            --disable-runcommand-onend)
                if disable_runcommand_onend; then
                    set_config "runcommand_onend" "false" > /dev/null
                    echo "runcommand-onend DISABLED."
                else
                    log "ERROR: failed to DISABLE runcommand-onend."
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
#H --restore-defaults                       Restore default files.
            --restore-defaults)
                restore_default_files
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
