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
# - imagemagick
# - librsvg2-bin


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
readonly TMP_SPLASHSCREEN="splashscreen.png"

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
readonly DEFAULT_SPLASHSCREEN_BACKGROUND="$SCRIPT_DIR/retropie-default.png"
readonly DEFAULT_TEXT_COLOR="white"
readonly DEFAULT_BACKGROUND_COLOR="black"

## Boot splashscreen
readonly DEFAULT_BOOT_SPLASHSCREEN_TEXT_COLOR="$DEFAULT_TEXT_COLOR"
readonly DEFAULT_BOOT_SPLASHSCREEN_BACKGROUND_COLOR="$DEFAULT_BACKGROUND_COLOR"

## Launching images
readonly DEFAULT_LAUNCHING_IMAGES_BACKGROUND_COLOR="$DEFAULT_BACKGROUND_COLOR"
readonly DEFAULT_LAUNCHING_IMAGES_TEXT_COLOR="$DEFAULT_TEXT_COLOR"
readonly DEFAULT_LAUNCHING_IMAGES_PRESS_BUTTON_TEXT="Press a button to configure launch options"
readonly DEFAULT_LAUNCHING_IMAGES_PRESS_BUTTON_TEXT_COLOR="$DEFAULT_TEXT_COLOR"

## Automate scripts
readonly DEFAULT_BOOT_SCRIPT="false"
readonly DEFAULT_LOG="false"

# Flags
GUI_FLAG=0
CONFIG_FLAG=0

# Global variables
SPLASH_PATH=
TEXT_COLOR=
BG_COLOR=
PRESS_BUTTON_TEXT=
BOOT_SCRIPT=
LOG=
OPTION=


# External resources ######################################

source "./utils/base.sh"
source "./utils/dialogs.sh"
source "./utils/imagemagick.sh"


# Functions ############################################

function check_log_file(){
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" && chown -R "$user":"$user" "$LOG_FILE"
    fi
}


function log() {
    check_log_file
    if [[ "$GUI_FLAG" -eq 1 ]] ; then
        echo "$(date +%F\ %T) - (v$SCRIPT_VERSION) GUI: $* << ${FUNCNAME[@]:1:((${#FUNCNAME[@]}-3))} $OPTION" >> "$LOG_FILE" # -2 are log ... get_options main main
        echo "$*"
    else
        echo "$(date +%F\ %T) - (v$SCRIPT_VERSION) $* << ${FUNCNAME[@]:1:((${#FUNCNAME[@]}-3))} $OPTION" >> "$LOG_FILE" # -2 are log ... get_options main main
        echo "$*" >&2
    fi
}


function download_default_splashscreen_background() {
    if curl -s -f "https://raw.githubusercontent.com/RetroPie/retropie-splashscreens/master/retropie-default.png" -o "$DEFAULT_SPLASHSCREEN_BACKGROUND"; then
        chown -R "$user":"$user" "$DEFAULT_SPLASHSCREEN_BACKGROUND"
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
    download_default_splashscreen_background || return 1
    download_config_file || return 1
    download_fun_facts || return 1
}


function check_default_files() {
    [[ ! -f "$DEFAULT_SPLASHSCREEN_BACKGROUND" ]] && download_default_splashscreen_background
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


function reset_config() {
    while read line; do
        set_config "$line" ""
    done < <(grep -Po ".*?(?=\ = )" "$SCRIPT_CFG")
}


function check_config() {
    CONFIG_FLAG=1

    SPLASH_PATH="$(get_config "splashscreen_path")"
    TEXT_COLOR="$(get_config "text_color")"
    BG_COLOR="$(get_config "bg_color")"
    PRESS_BUTTON_TEXT="$(get_config "press_button_text")"
    BOOT_SCRIPT="$(get_config "boot_script")"

    validate_splash "$SPLASH_PATH" || exit 1
    validate_color "$TEXT_COLOR" || exit 1
    validate_color "$BG_COLOR" || exit 1
    validate_true_false "boot_script" "$BOOT_SCRIPT" || exit 1

    if [[ -z "$SPLASH_PATH" ]]; then
        SPLASH_PATH="$DEFAULT_SPLASHSCREEN_BACKGROUND"
        set_config "splashscreen_path" "$SPLASH_PATH" > /dev/null
    fi

    if [[ -z "$TEXT_COLOR" ]]; then
        TEXT_COLOR="$DEFAULT_BOOT_SPLASHSCREEN_TEXT_COLOR"
        set_config "text_color" "$TEXT_COLOR" > /dev/null
    fi

    if [[ -z "$BG_COLOR" ]]; then
        BG_COLOR="$DEFAULT_BOOT_SPLASHSCREEN_BACKGROUND_COLOR"
        set_config "bg_color" "$BG_COLOR" > /dev/null
    fi
    
    if [[ -z "$PRESS_BUTTON_TEXT" ]]; then
        PRESS_BUTTON_TEXT="$LAUNCHING_IMAGES_PRESS_BUTTON_TEXT"
        set_config "press_button_text" "$PRESS_BUTTON_TEXT" > /dev/null
    fi
    
    if [[ -z "$BOOT_SCRIPT" ]]; then
        BOOT_SCRIPT="$DEFAULT_BOOT_SCRIPT"
        set_config "boot_script" "$BOOT_SCRIPT" > /dev/null
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
            echo "$config_file" > "$SCRIPT_CFG" && dialog_msgbox "Success!" "Config file updated."
        fi
    else
        nano "$SCRIPT_CFG"
    fi
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


function enable_launching_images() {
    if [[ ! -f "$RUNCOMMAND_ONEND" ]]; then
        touch "$RUNCOMMAND_ONEND" && chown -R "$user":"$user" "$RUNCOMMAND_ONEND"
        cat > "$RUNCOMMAND_ONEND" << _EOF_
#!/usr/bin/env bash
# $(basename "$RUNCOMMAND_ONEND")

_EOF_
    fi
    local command="\"$SCRIPT_RUNCOMMAND_ONEND\" \"\$1\" \"\$2\" \"\$3\" \"\$4\""
    disable_launching_images # deleting any previous config (do nothing if there isn't).
    sed -i "\$a$command" "$RUNCOMMAND_ONEND"
    local return_value="$?"
    [[ "$return_value" -eq 0 ]] || return 1
    check_runcommand_onend
}


function disable_launching_images() {
    sed -i "/[^# ]$(basename "$SCRIPT_RUNCOMMAND_ONEND")/d" "$RUNCOMMAND_ONEND"
    local return_value="$?"
    [[ "$return_value" -eq 0 ]] || return 1
    ! check_runcommand_onend
}


function check_runcommand_onend() {
    grep -q "$SCRIPT_RUNCOMMAND_ONEND" "$RUNCOMMAND_ONEND"
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
        # Note: the find function below returns the full path file name.
        font="$(find "$ES_THEMES_DIR/$theme/" -type f -name '*.ttf' -print -quit)"
        if [[ -z "$font" ]]; then
            log "ERROR: Unable to get the font from the '$theme' theme files."
            echo "Aborting ..." >&2
            exit 1
        fi
    fi
    echo "$font"
}


function get_system_logo() {
    if [[ ! -f "$ES_THEMES_DIR/$theme/$system/theme.xml" ]]; then
        #~ system_path="${logo%/}"
        #~ system="${system_path##*/}"
        if [[ "$system" = *"mame-"* ]]; then
            system="mame"
            #~ logo="$(get_system_logo)"
        fi
    fi
    local logo
    logo="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed') or contains(@name,'system')]/image[@name='logo']/path" \
        "$ES_THEMES_DIR/$theme/$system/theme.xml" 2> /dev/null | head -1)"
    logo="$ES_THEMES_DIR/$theme/$system/$logo"
    echo "$logo"
}


function get_console() {
    local console
    console="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed') or contains(@name,'system')]/image[@name='console_overlay']/path" \
        "$ES_THEMES_DIR/$theme/$system/theme.xml" 2> /dev/null | head -1)"
    console="$ES_THEMES_DIR/$theme/$system/$console"
    if [[ -f "$console" ]]; then
        echo "$console"
    else
        return 1
    fi
}

function get_boxart() {
    [[ -z "$rom_path" ]]  && return 1
    [[ ! -f "$rom_path" ]] && return 1
    local rom_name
    rom_name="$(basename "$rom_path")"
    local boxart
    boxart="$(xmlstarlet sel -t -v \
        "/gameList/game[path=\"./$rom_name\"]/image" \
        "$RP_ROMS_DIR/$system/gamelist.xml" 2> /dev/null | head -1)"
    boxart="$RP_ROMS_DIR/$system/$boxart"
    if [[ -f "$boxart" ]]; then
        echo "$boxart"
    else
        return 1
    fi
}

get_all_systems() {
    local all_systems=()
    local system_dir
    local system
    for system_dir in "$RP_CONFIG_DIR/"*; do
        system="$(basename "$system_dir")"
        if [[ "$system" != "all" ]]; then
            all_systems+=("$system")
        fi
    done
    echo "${all_systems[@]}"
}


function create_fun_fact() {
    local theme
    theme="$(get_current_theme)"
    local random_fact
    random_fact="$(shuf -n 1 "$FUN_FACTS_TXT")"
    local screen_w=1024
    local screen_h=576
    
    mkdir -p "$TMP_DIR" && chown -R "$user":"$user" "$TMP_DIR"

    if [[ -z "$1" ]]; then
        create_fun_fact_boot
        local return_value
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            if [[ -f "$RESULT_SPLASH" ]]; then
                if [[ ! -f "$SPLASH_LIST" ]]; then
                    touch "$SPLASH_LIST" && chown -R "$user":"$user" "$SPLASH_LIST"
                fi
                echo "$RESULT_SPLASH" > "$SPLASH_LIST"
            fi
        fi
    else
        create_fun_fact_launching "$@"
    fi
    
    rm -r "$TMP_DIR"
}


function create_fun_fact_boot() {
    local system="retropie"
    
    local logo
    logo="$(get_system_logo)"
    
    local splash
    splash="$(get_config "boot_splashscreen_background_path")"
    
    local bg_color
    bg_color="$(get_config "boot_splashscreen_background_color")"
    
    local text_color
    text_color="$(get_config "boot_splashscreen_text_color")"
    [[ -z "$text_color" ]] &&  text_color="$DEFAULT_TEXT_COLOR"
    
    local font
    font="$(get_config "boot_splashscreen_text_font")"
    [[ -z "$font" ]] && font="$(get_font)"
    
    local size_x="$(((screen_w*75/100)))"
    local size_y="$(((screen_h*15/100)))"
    
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --infobox "Creating Fun Facts! boot splashscreen ..." 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
    else
        echo "Creating Fun Facts! boot splashscreen ..."
    fi
    
    if [[ -z "$splash" ]]; then
        [[ -z "$bg_color" ]] &&  bg_color="$DEFAULT_BACKGROUND_COLOR"
        IM_add_background
        if [[ -f "$logo" ]]; then
            IM_add_logo
        fi
        if get_console > /dev/null; then
            IM_add_console
        fi
        splash="$TMP_DIR/splashscreen.png"
    else
        local bg_color="none"
    fi
    
    # Add Fun Fact!
    convert "$splash" \
        -size "$size_x"x"$size_y" \
        -background "$bg_color" \
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
        local success_message="Fun Facts! boot splashscreen successfully created!"
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            dialog_msgbox "Success!" "$success_message"
        else
            echo "$success_message"
        fi
    else
        local error_message="Fun Facts! boot splashscreen failed!"
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            log "$error_message" > /dev/null
            dialog_msgbox "Error!" "$error_message"
        else
            log "$error_message"
        fi
        return 1
    fi
}


function create_fun_fact_launching() {
    local system="$1"
    local rom_path="$2"
    
    local splash    
    splash="$(get_config "launching_images_background_path")"
    
    local bg_color
    bg_color="$(get_config "launching_images_background_color")"
    
    local font
    font="$(get_config "launching_images_text_font_path")"
    [[ -z "$font" ]] && font="$(get_font)"

    local press_button_text
    press_button_text="$(get_config "launching_images_press_button_text")"
    [[ -z "$press_button_text" ]] &&  press_button_text="$DEFAULT_LAUNCHING_IMAGES_PRESS_BUTTON_TEXT"
    
    local logo
    logo="$(get_system_logo)"
    
    if [[ "$system" == "all" ]]; then
        local system_dir
        for system_dir in "$RP_CONFIG_DIR/"*; do
            system_dir="$(basename "$system_dir")"
            if [[ "$system_dir" != "all" ]]; then
                if [[ "$system_dir" != *.* ]]; then # In case there a file that's not a directory
                    create_fun_fact_launching "$system_dir"
                fi
            fi
        done
    else
        if [[ -n "$rom_path" ]]; then
            [[ ! -f "$rom_path" ]] && log "ERROR: Not a valid rom path!" && exit 1
            # TODO: Check if EmulationStation scraped images exist.
            if [[ ! -f "$RP_ROMS_DIR/$system/images/$(basename "${rom_path%.*}")-image.jpg" ]]; then
                log "ERROR: '$(basename "${rom_path%.*}")' doesn't have a scraped image!"
                rom_path=""
                local result_splash="$RP_CONFIG_DIR/$system/$TMP_SPLASHSCREEN"
                echo "Creating launching image for '$system' ..."            
            else
                local result_splash="$RP_ROMS_DIR/$system/images/$(basename "${rom_path%.*}")-$TMP_SPLASHSCREEN"
                echo "Creating launching image for '$system - $(basename "${rom_path%.*}")' ..."
            fi
        else    
            [[ ! -d "$RP_CONFIG_DIR/$system" ]] && log "ERROR: '$system' folder doesn't exist!" && exit 1
            local result_splash="$RP_CONFIG_DIR/$system/$TMP_SPLASHSCREEN"
            echo "Creating launching image for '$system' ..."
        fi

        if [[ -z "$splash" ]]; then
            [[ -z "$bg_color" ]] &&  bg_color="$DEFAULT_BACKGROUND_COLOR"
            IM_add_background
        else
            local screen_w="$(identify -format "%w" "$splash")"
            local screen_h="$(identify -format "%h" "$splash")"
            cp "$splash" "$TMP_DIR/$TMP_SPLASHSCREEN"
        fi
    
        if [[ -f "$logo" ]]; then
            IM_add_logo
        fi
        if get_boxart > /dev/null; then
            IM_add_boxart
        elif get_console > /dev/null; then
            IM_add_console
        fi
        IM_add_fun_fact
        IM_add_press_button_text

        [[ -f "$result_splash" ]] && rm "$result_splash"
        mv "$TMP_DIR/$TMP_SPLASHSCREEN" "$result_splash" && chown -R "$user":"$user" "$result_splash"
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

        #~ if check_boot_script; then
            #~ option_boot="enabled"
        #~ else
            #~ option_boot="disabled"
        #~ fi

        #~ if [[ "$SCRIPT_DIR" == "$SCRIPTMODULE_DIR" ]]; then # If script is used as a scriptmodule
            #~ option_updates="Update script"
        #~ else
            #~ check_updates
            #~ option_updates="Update script ($updates_output)"
        #~ fi

        #~ options=(
            #~ 1 "Set splashscreen path ($(get_config "splashscreen_path"))"
            #~ 2 "Set text color ($(get_config "text_color"))"
            #~ 3 "Add a new Fun Fact!"
            #~ 4 "Remove Fun Facts!"
            #~ 5 "Create a new Fun Facts! Splashscreen"
            #~ 6 "Enable/Disable script at boot ($option_boot)"
            #~ 7 "Edit config file"
            #~ 8 "Reset config file"
            #~ 9 "$option_updates"
            #~ 10 "Restore default files"
        #~ )
        
        options=(
            1 "Splashscreens settings"
            2 "Fun Facts! settings"
            "-" "----------"
            3 "Create Fun Facts! splashscreens"
            "-" "----------"
            4 "Automate scripts"
            "-" "----------"
            5 "Configuration file"
            6 "Restore default files"
            "-" "----------"
            7 "Update script"
        )
        menu_items="$(((${#options[@]} / 2)))"
        if [[ "$SCRIPT_DIR" == "$SCRIPTMODULE_DIR" ]]; then # If script is used as a scriptmodule
            menu_text="Version: $version"
        else
            #~ last_commit="$(get_last_commit)"
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
                "-")
                    :
                    ;;
                1)
                    dialog_splashscreens_settings
                    ;;
                2)
                   dialog_fun_facts_settings 
                    ;;
                3)
                    local validation
                    validation="$(is_fun_facts_empty)"
                    if [[ -n "$validation" ]]; then
                        dialog_msgbox "Error!" "$validation"
                    else
                        dialog_create_fun_facts_splashscreens
                    fi
                    ;;
                4)
                    #~ Autome scripts
                        #~ - Enable/disable boot splashscreen
                        #~ - Enable/disable launching images
                        
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
                5)
                    #~ - Edit config
                    #~ - Reset config
   
                    #~ edit_config
                    #~ reset_config
                    ;;
                6)
                    local validation
                    validation="$(restore_default_files)"
                    if [[ -n "$validation" ]]; then
                        local title="Error!"
                        local text="$validation"
                    else
                        local title="Success!"
                        local text="Default files restored successfully!"
                            text+="\n\n"
                            text+="\n- ./$(basename "$DEFAULT_SPLASHSCREEN_BACKGROUND")" \
                            text+="\n- ./$(basename "$SCRIPT_CFG")" \
                            text+="\n- ./$(basename "$FUN_FACTS_TXT")"
                    fi
                    dialog \
                        --backtitle "$DIALOG_BACKTITLE" \
                        --title "$title" \
                        --msgbox "$text" 12 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                    ;;
                7)
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
                #~ 8)
                    #~ ;;
                #~ 9)
                    #~ ;;
                #~ 10)
                    #~ ;;
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
#H --enable-launching-images                Enable launching images.
            --enable-launching-images)
                if enable_launching_images; then
                    set_config "launching_images" "true" > /dev/null
                    echo "Launching images ENABLED."
                else
                    log "ERROR: failed to ENABLE launching images."
                fi
                ;;
#H --disable-launching-images               Disable launching images.
            --disable-launching-images)
                if disable_launching_images; then
                    set_config "launching_images" "false" > /dev/null
                    echo "Launching images DISABLED."
                else
                    log "ERROR: failed to DISABLE launching images."
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
#H --restore-defaults                       Restore default files.
            --restore-defaults)
                restore_default_files
                ;;
            *)
                log "ERROR: Invalid option '$1'."
                log "Try 'sudo $0 --help' for more info."
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

    check_boot="$(get_config "boot_script")"
    if [[ "$check_boot" == "false" || "$check_boot" == "" ]]; then
        disable_boot_script
    elif [[ "$check_boot" == "true" ]]; then
        enable_boot_script
    fi

    check_default_files

    mkdir -p "$RP_DIR/splashscreens" && chown -R "$user":"$user" "$RP_DIR/splashscreens"

    chown -R "$user":"$user" .

    get_options "$@"
}

main "$@"
