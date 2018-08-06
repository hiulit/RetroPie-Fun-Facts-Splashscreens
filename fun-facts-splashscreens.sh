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
readonly TMP_DIR="$home/tmp"
readonly TMP_SPLASHSCREEN="splashscreen.png"
readonly DEPENDENCIES=("imagemagick" "librsvg2-bin")

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
readonly RESULT_BOOT_SPLASH="$RP_DIR/splashscreens/fun-facts-splashscreen.png"
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

# Flags
GUI_FLAG=0

# Global variables
RESULT_SPLASH=
OPTION=
DEFAULT_FILES=(
    "$SCRIPT_CFG"
    "$FUN_FACTS_TXT"
    "$DEFAULT_SPLASHSCREEN_BACKGROUND"
)
DEFAULT_THEME="carbon"
ERRORS=0


# External resources ######################################

source "$SCRIPT_DIR/utils/base.sh"
source "$SCRIPT_DIR/utils/dialogs.sh"
source "$SCRIPT_DIR/utils/imagemagick.sh"


# Functions ############################################

function download_github_file() {
    local file_path="$1"
    local file_name
    file_name="$(basename "$file_path")"
    if curl -s -f "https://raw.githubusercontent.com/hiulit/RetroPie-Fun-Facts-Splashscreens/new-gui-menu/$file_name" -o "$file_path"; then
        chown -R "$user":"$user" "$file_path"
        echo "'$file_name' downloaded successfully!"
    else
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            log "Can't download '$file_name'."
        else
            log "ERROR: Can't download '$file_name'."
        fi
        return 1
    fi
}


function restore_default_files() {
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        local text="Would you like to restore the default files?"
        text+="\n"
        for file in "${DEFAULT_FILES[@]}"; do
            text+="\n- '$(basename "$file")'"
        done
        text+="\n\n"
        text+="This action will overwrite those files and erase any changes you may have made to them."
        echo "$text"
        dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --title "Warning" \
            --yesno "$text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH"
    else
        echo "Would you like to restore the default files?"
        echo
        for file in "${DEFAULT_FILES[@]}"; do
            echo "- '$(basename "$file")'"
        done
        echo
        echo "This action will overwrite those files and erase any changes you may have made to them."
        local options=("Yes" "No")
        select option in "${options[@]}"; do
            case "$option" in
                Yes)
                    for file in "${DEFAULT_FILES[@]}"; do
                        download_github_file "$file"
                    done
                    exit 1
                    ;;
                No)
                    exit 1
                    ;;
                *)
                    echo "Invalid option. Choose a number between 1 and ${#options[@]}."
                    ;;
            esac
        done
    fi
}


function check_default_files() {
    for file in "${DEFAULT_FILES[@]}"; do
        [[ ! -f "$file" ]] && download_github_file "$file"
    done
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


function edit_config() {
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        local config_file
        config_file="$(dialog \
                    --backtitle "$DIALOG_BACKTITLE" \f
                    --title "Edit configuration file" \
                    --ok-label "Save" \
                    --cancel-label "Back" \
                    --editbox "$SCRIPT_CFG" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
        local result_value="$?"
        if [[ "$result_value" == "$DIALOG_OK" ]]; then
            echo "$config_file" > "$SCRIPT_CFG" && dialog_msgbox "Success!" "Configuration file updated."
        else
            dialog_configuration_file
        fi
    else
        nano "$SCRIPT_CFG"
    fi
}


function backup_config() {
    if [[ -f "$SCRIPT_CFG.bak" ]]; then
        restore_backup_config
    else
        if [[ -f "$SCRIPT_CFG" ]]; then
            cp "$SCRIPT_CFG" "$SCRIPT_CFG.bak"
            chown -R "$user":"$user" "$SCRIPT_CFG.bak"
        else
            log "ERROR: There isn't a configuration file to backup!"
        fi
    fi
}

function restore_backup_config() {
    rm "$SCRIPT_CFG"
    cp "$SCRIPT_CFG.bak" "$SCRIPT_CFG"
    chown -R "$user":"$user" "$SCRIPT_CFG"
    rm "$SCRIPT_CFG.bak"
}


function enable_boot_splashscreen() {
    local command="\"$SCRIPT_FULL\" --create-fun-fact \&"
    disable_boot_splashscreen # deleting any previous config (do nothing if there isn't).
    sed -i "s|^exit 0$|${command}\\nexit 0|" "$RCLOCAL"
    local return_value="$?"
    [[ "$return_value" -eq 0 ]] || return 1
    assure_safe_exit_boot_splashscreen
    check_boot_splashscreen
}


function disable_boot_splashscreen() {
    sed -i "/$(basename "$0")/d" "$RCLOCAL"
    local return_value="$?"
    [[ "$return_value" -eq 0 ]] || return 1
    assure_safe_exit_boot_splashscreen
    ! check_boot_splashscreen
}


function assure_safe_exit_boot_splashscreen() {
    grep -q '^exit 0$' "$RCLOCAL" || echo "exit 0" >> "$RCLOCAL"
}


function check_boot_splashscreen() {
    grep -q "$SCRIPT_DIR" "$RCLOCAL"
}

function create_runcommand_onend() {
    if [[ ! -f "$RUNCOMMAND_ONEND" ]]; then
        touch "$RUNCOMMAND_ONEND" && chown -R "$user":"$user" "$RUNCOMMAND_ONEND" && chmod +x "$RUNCOMMAND_ONEND"
        cat > "$RUNCOMMAND_ONEND" << _EOF_
#!/usr/bin/env bash
# $(basename "$RUNCOMMAND_ONEND")

_EOF_
    fi
}


function enable_launching_images() {
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
    if [[ ! -f "$home/.emulationstation/es_settings.cfg" ]]; then
        echo "$DEFAULT_THEME"
    else
        sed -n "/name=\"ThemeSet\"/ s/^.*value=['\"]\(.*\)['\"].*/\1/p" "$home/.emulationstation/es_settings.cfg"
    fi
}


function get_font() {
    local theme
    theme="$(get_current_theme)"
    if [[ -z "$theme" ]]; then
        echo "WARNING: Couldn't get the current theme."
        echo "Switching to the default's theme ..."
        theme="$DEFAULT_THEME"
    fi
    local font
    font="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed')]/textlist/fontPath" \
        "$ES_THEMES_DIR/$theme/$theme.xml" 2> /dev/null)"

    if [[ -n "$font" ]]; then
        font="$ES_THEMES_DIR/$theme/$font"
    else
        # Note: the find function below returns the full path file name.
        font="$(find "$ES_THEMES_DIR/$theme/" -type f -name '*.ttf' -print -quit 2> /dev/null)"
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
        if [[ "$system" = *"mame-"* ]]; then
            system="mame"
        fi
    fi
    local logo
    logo="$(xmlstarlet sel -t -v \
        "/theme/view[contains(@name,'detailed') or contains(@name,'system')]/image[@name='logo']/path" \
        "$ES_THEMES_DIR/$theme/$system/theme.xml" 2> /dev/null | head -1)"
    logo="$ES_THEMES_DIR/$theme/$system/$logo"
    if [[ -f "$logo" ]]; then
        echo "$logo"
    else
        return 1
    fi
}


function get_console() {
    if [[ ! -f "$ES_THEMES_DIR/$theme/$system/theme.xml" ]]; then
        if [[ "$system" = *"mame-"* ]]; then
            system="mame"
        fi
    fi
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
    if [[ ! -f "$rom_path" ]]; then
        local rom_name="$rom_path"
        if [[ ! -f "$RP_ROMS_DIR/$system/$rom_name" ]];then
            return 1
        else
            local rom_name
            rom_name="$(basename "$rom_path")"
        fi
    fi
    local game_list="$RP_ROMS_DIR/$system/gamelist.xml" # Using SSelph scraper option: 'Use rom folder for gamelist & images' or SkyScraper.
    if [[ ! -f "$game_list" ]]; then
        game_list="/home/pi/.emulationstation/gamelists/$system/gamelist.xml" # Default EmulationStation gamelist.xml.
    fi
    local boxart
    boxart="$(xmlstarlet sel -t -v \
        "/gameList/game[path[contains(text(),\"$rom_name\")]]/image" \
        "$game_list" 2> /dev/null | head -1)"
    [[ "$boxart" == "."* ]] && boxart="$RP_ROMS_DIR/$system/$boxart" # If path start with "."
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
        local return_value="$?"
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
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --infobox "Creating Fun Facts! boot splashscreen ..." 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
    else
        [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "Creating Fun Facts! boot splashscreen ..."
    fi

    RESULT_SPLASH="$RESULT_BOOT_SPLASH"

    local system="retropie"

    local logo
    logo="$(get_system_logo)"

    local splash
    splash="$(get_config "boot_splashscreen_background_path")"

    local bg_color
    bg_color="$(get_config "boot_splashscreen_background_color")"
    if [[ -z "$bg_color" ]]; then
        bg_color="$DEFAULT_BACKGROUND_COLOR"
    else
        validate_color "$bg_color"
        local return_value="$?"
        [[ "$return_value" -eq 1 ]] && exit 1
    fi

    local text_color
    text_color="$(get_config "boot_splashscreen_text_color")"
    if [[ -z "$text_color" ]]; then
        text_color="$DEFAULT_TEXT_COLOR"
    else
        validate_color "$text_color"
        local return_value="$?"
        [[ "$return_value" -eq 1 ]] && exit 1
    fi

    local font
    font="$(get_config "boot_splashscreen_text_font_path")"
    if [[ -z "$font" ]]; then
        font="$(get_font)"
    else
        if [[ ! -f "$font" ]]; then
            [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "WARNING: Couldn't find the font path set in 'boot_splashscreen_text_font_path'. Check configuration file."
            [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "Trying to use the current theme's font ..."
            font="$(get_font)"
        fi
    fi

    local size_x="$(((screen_w*75/100)))"
    local size_y="$(((screen_h*15/100)))"

    if [[ -z "$splash" ]]; then
        IM_add_background
        if [[ -f "$logo" ]]; then
            IM_add_logo
        fi
        if get_console > /dev/null; then
            IM_add_console
        fi
        splash="$TMP_DIR/splashscreen.png"
    else
        bg_color="none"
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
        local success_message="Fun Facts! boot splashscreen created successfully!"
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            dialog_msgbox "Success!" "$success_message"
        else
            [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "$success_message"
        fi
    else
        local error_message="Fun Facts! boot splashscreen failed!"
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            dialog_msgbox "Error!" "$error_message"
        else
            log "ERROR: $error_message"
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
    if [[ -z "$bg_color" ]]; then
        bg_color="$DEFAULT_BACKGROUND_COLOR"
    else
        validate_color "$bg_color"
        local return_value="$?"
        [[ "$return_value" -eq 1 ]] && exit 1
    fi

    local text_color
    text_color="$(get_config "launching_images_text_color")"
    if [[ -z "$text_color" ]]; then
        text_color="$DEFAULT_TEXT_COLOR"
    else
        validate_color "$text_color"
        local return_value="$?"
        [[ "$return_value" -eq 1 ]] && exit 1
    fi

    local font
    font="$(get_config "launching_images_text_font_path")"
    if [[ -z "$font" ]]; then
        font="$(get_font)"
    else
        if [[ ! -f "$font" ]]; then
            [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "WARNING: Couldn't find the font path set in 'launching_images_text_font_path'. Check configuration file."
            [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "Trying to use the current theme's font ..."
            font="$(get_font)"
        fi
    fi

    local press_button_text
    press_button_text="$(get_config "launching_images_press_button_text")"
    [[ -z "$press_button_text" ]] && press_button_text="$DEFAULT_LAUNCHING_IMAGES_PRESS_BUTTON_TEXT"

    local press_button_text_color
    press_button_text_color="$(get_config "launching_images_press_button_text_color")"
    if [[ -z "$press_button_text_color" ]]; then
        press_button_text_color="$DEFAULT_TEXT_COLOR"
    else
        validate_color "$press_button_text_color"
        local return_value="$?"
        [[ "$return_value" -eq 1 ]] && exit 1
    fi

    local logo
    logo="$(get_system_logo)"

    if [[ "$system" == "all" ]]; then
        local system_dir
        for system_dir in "$RP_CONFIG_DIR/"*; do
            system_dir="$(basename "$system_dir")"
            if [[ "$system_dir" != "all" ]]; then
                if [[ "$system_dir" != *.* ]]; then # In case there's a file that's not a directory
                    create_fun_fact_launching "$system_dir"
                fi
            fi
        done
    else
        if [[ -n "$rom_path" ]]; then
            if [[ ! -f "$rom_path" ]]; then # If full ROM path doesn't exist
                rom_file="$rom_path"
                if [[ ! -f "$RP_ROMS_DIR/$system/$rom_file" ]]; then # Try to use /home/pi/RetroPie/roms/$system/$rom_file
                    log "ERROR: '$RP_ROMS_DIR/$system/$rom_file' is not a valid ROM path!"
                    log "Check if the system '$system' and the ROM '$rom_file' are correct."
                    log "Remember to add the file extension of the ROM."
                    exit 1
                else
                    rom_ext="${rom_file#*.}"
                    rom_file="${rom_file%.*}"
                fi
            else
                rom_ext="$(basename "${rom_path#*.}")"
                rom_file="$(basename "${rom_path%.*}")"
            fi
            if get_boxart > /dev/null; then
                mkdir -p "$RP_ROMS_DIR/$system/images" && chown -R "$user":"$user" "$RP_ROMS_DIR/$system/images"
                RESULT_SPLASH="$RP_ROMS_DIR/$system/images/${rom_file}-launching.png"
                [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "Creating Fun Facts! launching image for '$system - $rom_file' ..."
            else
                log "ERROR: '$RP_ROMS_DIR/$system/$rom_file.$rom_ext' doesn't have a scraped image!"
                rom_path=""
                RESULT_SPLASH="$RP_CONFIG_DIR/$system/launching.png"
                [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "Can't create launching image with boxart without a scraped image." >&2
                [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "Switching to default launching image for '$system' ..."
                [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "Creating Fun Facts! launching image for '$system' ..."
            fi
        else
            [[ ! -d "$RP_CONFIG_DIR/$system" ]] && log "ERROR: '$system' is not a valid system." && exit 1
            RESULT_SPLASH="$RP_CONFIG_DIR/$system/launching.png"
            if [[ "$GUI_FLAG" -eq 1 ]]; then
                dialog_info "Creating Fun Facts! launching image for '$system' ..."
            else
                [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "Creating Fun Facts! launching image for '$system' ..."
            fi
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

        # TODO: better handling of errors.
        local return_value="$?"
        if [[ "$ERRORS" -eq 0 ]]; then
            [[ -f "$RESULT_SPLASH" ]] && rm "$RESULT_SPLASH"
            mv "$TMP_DIR/$TMP_SPLASHSCREEN" "$RESULT_SPLASH" && chown -R "$user":"$user" "$RESULT_SPLASH"
            local success_message="Fun Facts! launching image for '$system' created successfully!"
            if [[ "$GUI_FLAG" -eq 1 ]]; then
                dialog_info "$success_message" && sleep 1
            else
                [[ "$RUNCOMMAND_ONEND_FLAG" -eq 0 ]] && echo "$success_message"
            fi
        else
            local error_message="Fun Facts! launching image for '$system' failed!"
            if [[ "$GUI_FLAG" -eq 1 ]]; then
                dialog_msgbox "Error!" "$error_message"
            else
                log "ERROR: $error_message" >&2
            fi

        fi
    fi
}


function select_fun_facts() {
    local fun_facts=()
    local fun_facts_total
    local options
    local start="$1"
    local items="$2"
    local next="NEXT -->"
    local prev="<-- PREVIOUS"
    local quit="QUIT"
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

    underline "Choose a Fun Fact! to remove"
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
            echo "'$FUN_FACTS_TXT' is empty!"
            return 1
        else
            echo "ERROR: '$FUN_FACTS_TXT' is empty!" >&2
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
                echo "'$1' Fun Fact! is already in '$FUN_FACTS_TXT'"
                return 1
            else
                echo "ERROR: '$1' Fun Fact! is already in '$FUN_FACTS_TXT'" >&2
                exit 1
            fi
        fi
    done < "$FUN_FACTS_TXT"
    echo "$1" >> "$FUN_FACTS_TXT" && echo "'$1' Fun Fact! added successfully!"
}


function remove_fun_fact() {
    is_fun_facts_empty
    if [[ -n "$1" ]]; then
        sed -i "/^$1$/ d" "$FUN_FACTS_TXT"
    else
        select_fun_facts 0 5
        sed -i "/^$option$/ d" "$FUN_FACTS_TXT" # $option comes from select_fun_facts()
        echo "'$option' Fun Fact! removed successfully!" && sleep 0.5
        remove_fun_fact
    fi
}


function validate_color() {
    [[ -z "$1" ]] && return 0

    if convert -list color | grep -q "^$1\b"; then
        return 0
    else
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            log "Can't set/get the text color. Invalid color: '$1'."
            log "Check the 'XXX_text_color' values in '$SCRIPT_CFG'"
        else
            log "ERROR: Can't set/get the color. Invalid color: '$1'."
            echo "Check the 'XXX_color' values in '$SCRIPT_CFG'" >&2
            echo >&2
            underline "Short list of available colors:" >&2
            echo "black white gray gray10 gray25 gray50 gray75 gray90" >&2
            echo "pink red orange yellow green silver blue cyan purple brown" >&2
            echo >&2
            echo "TIP: run the 'convert -list color' command to get a full list." >&2
        fi
        return 1
    fi
}


function check_major_version() {
    local git_version
    git_version="$(git tag | sort -V | tail -1 | grep -Po "([0-9]{1,}\.)+[0-9]{1,}")"
    local script_version_major
    script_version_major="$(echo "$SCRIPT_VERSION" | grep -Po "^[0-9]")"
    local git_version_major
    git_version_major="$(echo "$git_version" | grep -Po "^[0-9]")"

    if [[ "$git_version_major" -gt "$script_version_major" ]]; then
        echo "WARNING: A new major version is released!" >&2
        echo "As major versions usually involve breaking changes, it's best to:" >&2
        echo "- Save or backup the default files (splashscreen image, configuration file and Fun Facts! file), if you made any changes to them." >&2
        echo "- Delete the 'RetroPie-Fun-Facts-Splashscreens' folder." >&2
        echo "- Go to 'https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/'" >&2
        echo "- Download and install the script again." >&2
        exit 1
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
        version="$SCRIPT_VERSION"

        if [[ "$SCRIPT_DIR" == "$SCRIPTMODULE_DIR" ]]; then # If script is used as a scriptmodule
            option_updates="Update script"
        else
            check_updates
            option_updates="Update script ($updates_output)"
        fi

        options=(
            1 "Splashscreens settings" "1 - Settings for boot splashscreens and launching images."
            2 "Fun Facts! settings" "2 - Add/Remove Fun Facts!"
            "-" "----------" ""
            3 "Create Fun Facts! splashscreens" "3 - Select which type of splashscreens to create (boot splashscreen or launching images)"
            "-" "----------" ""
            4 "Automate scripts" "4 - Enable/Disable scripts to automate the creation of splashscreens."
            "-" "----------" ""
            5 "Configuration file" "5 - Edit/Reset the configuration file"
            6 "Restore default files" "6 - Download (and overwrite) the default files from the source."
            "-" "----------" ""
            7 "$option_updates" "7 - Update the script."
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
            --item-help \
            --help-button \
            --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
        choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
        if [[ -n "$choice" ]]; then
            if [[ "${choice[@]:0:4}" == "HELP" ]]; then
                choice="${choice[@]:5}" # Removes 'HELP' from $choice
                choice="${choice#* - }" # Removes ' - ' from $choice
                dialog_msgbox "Help" "$choice"
            else
                case "$choice" in
                    "-")
                        : # Do nothing
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
                        dialog_automate_scripts
                        ;;
                    5)
                        dialog_configuration_file
                        ;;
                    6)
                        restore_default_files
                        local result_value="$?"
                        if [[ "$result_value" -eq "$DIALOG_OK" ]]; then
                            local text
                            for file in "${DEFAULT_FILES[@]}"; do
                                text+="-$(download_github_file "$file")\n"
                            done
                            local result_value="$?"
                            if [[ "$result_value" -eq 1 ]]; then
                                local title="Error!"
                            else
                                local title="Success!"
                            fi
                            dialog \
                                --backtitle "$DIALOG_BACKTITLE" \
                                --title "$title" \
                                --msgbox "$text" 12 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                        else
                            echo "no"
                        fi
                        # local validation
                        # validation="$(restore_default_files)"
                        # if [[ -n "$validation" ]]; then
                        #     local title="Error!"
                        #     local text="$validation"
                        # else
                        #     local title="Success!"
                        #     local text="Default files restored successfully!"
                        #         text+="\n\n"
                        #         for file in "${DEFAULT_FILES[@]}"; do
                        #             text+="\n- '$(basename "$file")'"
                        #         done
                        # fi
                        # dialog \
                        #     --backtitle "$DIALOG_BACKTITLE" \
                        #     --title "$title" \
                        #     --msgbox "$text" 12 "$DIALOG_WIDTH" 2>&1 >/dev/tty
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
                                # backup_config
                                git pull && chown -R "$user":"$user" .
                                # restore_backup_config
                            else
                                dialog_msgbox "Info" "Fun Facts! Splashscreens is $updates_output!"
                            fi
                        fi
                        ;;
                esac
            fi
        else
            break
        fi
    done
    clear
}


function get_options() {
    [[ -z "$1" ]] && usage

    OPTION="$1"

    while [[ -n "$1" ]]; do
        case "$1" in
#H -h,   --help                                 Print the help message.
            -h|--help)
                echo
                underline "$SCRIPT_TITLE"
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
#H -aff, --add-fun-fact [TEXT]                  Add new Fun Facts!.
            -aff|--add-fun-fact)
                check_argument "$1" "$2" || exit 1
                shift
                add_fun_fact "$1"
                ;;
#H -rff, --remove-fun-fact                      Remove Fun Facts!.
            -rff|--remove-fun-fact)
                remove_fun_fact
                ;;
#H -cff, --create-fun-fact ([SYSTEM] [ROM])     Create a new Fun Facts! Splashscreen.
#H                                                - No arguments: Create a boot splashscreen.
#H                                                - [SYSTEM]: Create a launching image for a given system.
#H                                                - [SYSTEM] [ROM]: Create a launching image for a given game.
            -cff|--create-fun-fact)
                is_fun_facts_empty
                if [[ -z "$2" ]]; then
                    create_fun_fact
                else
                    shift
                    create_fun_fact "$@"
                    shift
                fi
                ;;
#H -ebs, --enable-boot-splashscreen             Enable the script to create a boot splashscreen at startup.
            -ebs|--enable-boot-splashscreen)
                if enable_boot_splashscreen; then
                    set_config "boot_splashscreen_script" "true" > /dev/null
                    echo "Boot splashscreen script enabled."
                else
                    echo "ERROR: failed to enable boot splashscreen script." >&2
                fi
                ;;
#H -dbs, --disable-boot-splashscreen            Disable the script to create a boot splashscreen at startup.
            -dbs|--disable-boot-splashscreen)
                if disable_boot_splashscreen; then
                    set_config "boot_splashscreen_script" "false" > /dev/null
                    echo "Boot splashscreen script disabled."
                else
                    echo "ERROR: failed to disable boot splashscreen script." >&2
                fi
                ;;
#H -eli, --enable-launching-images              Enable the script to create launching images using 'runcommand-onend.sh'.
            -eli|--enable-launching-images)
                if enable_launching_images; then
                    set_config "launching_images_script" "true" > /dev/null
                    echo "Launching images script enabled."
                else
                    echo "ERROR: failed to enable launching images script." >&2
                fi
                ;;
#H -dli, --disable-launching-images             Disable the script to create launching images using 'runcommand-onend.sh'.
            -dli|--disable-launching-images)
                if disable_launching_images; then
                    set_config "launching_images_script" "false" > /dev/null
                    echo "Launching images script disabled."
                else
                    echo "ERROR: failed to disable launching images script." >&2
                fi
                ;;
#H -ec,  --edit-config                          Edit the configuration file.
            -ec|--edit-config)
                edit_config
                ;;
#H -rc,  --reset-config                         Reset the configuration file.
            -rc|--reset-config)
                reset_config
                ;;
#H -rd,  --restore-defaults                     Restore the default files.
            -rd|--restore-defaults)
                restore_default_files
                ;;
#H -g,   --gui                                  Start the GUI.
            -g|--gui)
                gui
                ;;
#H -u,   --update                               Update the script.
            -u|--update)
                check_updates
                if [[ "$updates_status" == "needs-to-pull" ]]; then
                    check_major_version
                    git pull && chown -R "$user":"$user" .
                fi
                ;;
#H -v,   --version                              Show the script version.
            -v|--version)
                echo "$SCRIPT_VERSION"
                ;;
            *)
                echo "ERROR: Invalid option '$1'." >&2
                echo "Try 'sudo $0 --help' for more info." >&2
                exit 2
                ;;
        esac
        shift
    done
}

function main() {
    if ! is_sudo; then
        echo "ERROR: '$(basename "$0")' must be run under 'sudo'." >&2
        echo "Try 'sudo ./$SCRIPT_NAME'." >&2
        exit 1
    fi

    if ! is_retropie; then
        echo "ERROR: RetroPie is not installed. Aborting ..." >&2
        exit 1
    fi

    check_dependencies

    create_runcommand_onend

    local check_boot_splashscreen
    check_boot_splashscreen="$(get_config "boot_splashscreen_script")"
    if [[ "$check_boot_splashscreen" == "false" || "$check_boot_splashscreen" == "" ]]; then
        disable_boot_splashscreen
    elif [[ "$check_boot_splashscreen" == "true" ]]; then
        enable_boot_splashscreen
    fi
    local check_launching_images
    check_launching_images="$(get_config "launching_images_script")"
    if [[ "$check_launching_images" == "false" || "$check_launching_images" == "" ]]; then
        disable_launching_images
    elif [[ "$check_launching_images" == "true" ]]; then
        enable_launching_images
    fi

    check_default_files

    mkdir -p "$RP_DIR/splashscreens" && chown -R "$user":"$user" "$RP_DIR/splashscreens"

    chown -R "$user":"$user" .

    get_options "$@"
}

main "$@"
