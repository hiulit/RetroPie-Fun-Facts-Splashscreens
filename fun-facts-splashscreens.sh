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

readonly SCRIPT_VERSION="1.5.0"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_CFG="$SCRIPT_DIR/fun-facts-splashscreens-settings.cfg"
readonly SCRIPT_TITLE="Fun Facts! Splashscreens for RetroPie"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to create splashscreens with random video game related fun facts."
readonly DEPENDENCIES=("imagemagick")


# Variables ############################################

readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun-facts.txt"
readonly RESULT_SPLASH="$RP_DIR/splashscreens/fun-facts-splashscreen.png"
readonly DEFAULT_SPLASH="$SCRIPT_DIR/retropie-default.png"
readonly DEFAULT_COLOR="white"
readonly DEFAULT_BOOT_SCRIPT="false"
readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_ESC=255

SPLASH_PATH=
TEXT_COLOR=
BOOT_SCRIPT=
ENABLE_BOOT_FLAG=0
DISABLE_BOOT_FLAG=0
CONFIG_FLAG=0
GUI_FLAG=0
RESET_CONFIG_FLAG=0


# Functions ############################################

function is_retropie() {
    [[ -d "$RP_DIR" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}


function check_dependencies() {
    local pkg
    for pkg in "${DEPENDENCIES[@]}";do
        if ! dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" > /dev/null; then
            echo "ERROR: The '$pkg' package is not installed!"
            echo "Would you like to install it now?"
            local options
            options=("Yes" "No")
            local option
            select option in "${options[@]}"; do
                case "$option" in
                    Yes)
                        if ! which apt-get > /dev/null; then
                            echo "ERROR: Couldn't install '$pkg' automatically. Try to install it manually." >&2
                            exit 1
                        else
                            sudo apt-get install "$pkg"
                            break
                        fi
                        ;;
                    No)
                        echo "ERROR: Can't launch the script if the '$pkg' package is not installed." >&2
                        exit 1
                        ;;
                    *)
                        echo "Invalid option. Select a number between 1 and ${#options[@]}."
                        ;;
                esac
            done
        fi
    done
}


function check_argument() {
    # XXX: this method doesn't accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo >&2
        echo "ERROR: '$1' is missing an argument." >&2
        echo >&2
        echo "Try 'sudo $0 --help' for more info." >&2
        echo >&2
        return 1
    fi
}


function set_config() {
    sed -i "s|^\($1\s*=\s*\).*|\1\"$2\"|" "$SCRIPT_CFG"
    echo "'$1' set to '$2'."
}


function get_config() {
    local config
    config="$(grep -Po "(?<=^$1 = ).*" "$SCRIPT_CFG")"
    config="${config%\"}"
    config="${config#\"}"
    echo "$config"
}


function check_config() {
    CONFIG_FLAG=1

    if [[ ! -f "$DEFAULT_SPLASH" ]]; then
        echo "Downloading Fun Facts! default splashscreen ..."
        curl -s "https://raw.githubusercontent.com/RetroPie/retropie-splashscreens/master/retropie-default.png" -o "retropie-default.png" > /dev/null
        echo "Downloading Fun Facts! default splashscreen ... OK"
        echo "Setting permissions to Fun Facts! default splashscreen ..."
        chown -R "$user":"$user" "retropie-default.png"
        echo "Setting permissions to Fun Facts! default splashscreen ... OK"
    fi

    if [[ ! -f "$SCRIPT_CFG" ]]; then
        echo "Downloading Fun Facts! config file ..."
        curl -s "https://raw.githubusercontent.com/hiulit/RetroPie-Fun-Facts-Splashscreens/master/fun-facts-splashscreens-settings.cfg" -o "fun-facts-splashscreens-settings.cfg" > /dev/null
        echo "Downloading Fun Facts! config file ... OK"
        echo "Setting permissions to Fun Facts! config file ..."
        chown -R "$user":"$user" "fun-facts-splashscreens-settings.cfg"
        echo "Setting permissions to Fun Facts! config file ... OK"
    fi
    
    if [[ ! -f "$FUN_FACTS_TXT" ]]; then
        echo "Downloading Fun Facts! text file ..."
        curl -s "https://raw.githubusercontent.com/hiulit/RetroPie-Fun-Facts-Splashscreens/master/fun-facts.txt" -o "fun-facts.txt" > /dev/null
        echo "Downloading Fun Facts! text file ... OK"
        echo "Setting permissions to Fun Facts! text file ..."
        chown -R "$user":"$user" "fun-facts.txt"
        echo "Setting permissions to Fun Facts! text file ... OK"
    fi

    echo "Checking config file ..."

    SPLASH_PATH="$(get_config "splashscreen_path")"
    TEXT_COLOR="$(get_config "text_color")"
    BOOT_SCRIPT="$(get_config "boot_script")"

    validate_splash "$SPLASH_PATH" || exit 1
    validate_color "$TEXT_COLOR" || exit 1
    validate_boot_script "$BOOT_SCRIPT" || exit 1

    echo "Checking config file ... OK"

    echo "Setting config file ..."

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

    echo "Setting config file ... OK"

    echo
    echo "Config file"
    echo "-----------"
    echo "'splashscreen_path'   = '$SPLASH_PATH'"
    echo "'text_color'          = '$TEXT_COLOR'"
    echo "'boot_script'         = '$BOOT_SCRIPT'"
    echo

    if [[ "$BOOT_SCRIPT" == "false" ]]; then
        disable_boot_script
    elif [[ "$BOOT_SCRIPT" == "true" ]]; then
        enable_boot_script
    fi
}


function reset_config() {
    echo "Resetting config file ..."
    set_config "splashscreen_path" ""
    set_config "text_color" ""
    set_config "boot_script" ""
    echo "Resetting config file ... OK"
}


function usage() {
    echo
    echo "USAGE: sudo $0 [OPTIONS]"
    echo
    echo "Use '--help' to see all the options."
    echo
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
    grep -q "$RESULT_SPLASH" "$SPLASH_LIST"
}


function apply_splash() {
    check_apply_splash
    return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            dialog \
                --backtitle "$SCRIPT_TITLE" \
                --msgbox "\nFun Facts! splashscreen is already applied.\n" 7 50 2>&1 >/dev/tty
        else
            echo
            echo "Fun Facts! splashscreen is already applied."
        fi
    else
        echo "$RESULT_SPLASH" >"$SPLASH_LIST"
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            dialog \
                --backtitle "$SCRIPT_TITLE" \
                --msgbox "\nFun Facts! splashscreen set succesfully!\n" 7 50 2>&1 >/dev/tty
        else
            echo "Fun Facts! splashscreen set succesfully!"
        fi
    fi
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
            echo "ERROR: Unable to get the font from the '$theme' theme files." >&2
            echo "Aborting ..." >&2
            exit 1
        fi
    fi
    echo "$font"
}


function create_fun_fact() {
    local splash="$(get_config "splashscreen_path")"
    local color="$(get_config "text_color")"
    local font="$(get_font)"
    local random_fact="$(shuf -n 1 "$FUN_FACTS_TXT")"

    if [[ "$GUI_FLAG" -eq 1 ]]; then
        dialog \
            --backtitle "$SCRIPT_TITLE" \
            --infobox "\nCreating Fun Facts! splashscreen ...\n" 5 50 2>&1 >/dev/tty
    else
        echo
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
    && [[ "$GUI_FLAG" -eq 1 ]] && dialog --backtitle "$SCRIPT_TITLE" --msgbox "\nFun Facts! splashscreen successfully created!\n" 7 50 2>&1 >/dev/tty || echo "Fun Facts! splashscreen successfully created!"
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


function add_fun_fact() {
    while IFS= read -r line; do
        if [[ "$1" == "$line" ]]; then
            if [[ "$GUI_FLAG" -eq 1 ]]; then
                echo "'$1' is already in '$FUN_FACTS_TXT'"
                return 1
            else
                echo "ERROR: '$1' is already in '$FUN_FACTS_TXT'"  >&2
                exit 1
            fi
        fi
    done < "$FUN_FACTS_TXT"
    echo "$1" >> "$FUN_FACTS_TXT"
    echo "'$1' Fun Fact! added succesfully!"
}


function check_fun_facts_txt() {
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


function remove_fun_fact() {
    if [[ -n "$1" ]]; then
        sed -i "/^$1$/ d" "$FUN_FACTS_TXT"
    else
        select_fun_facts 0 10
        echo "Removing Fun Fact! ... '$option'" && sleep 0.5
        sed -i "/^$option$/ d" "$FUN_FACTS_TXT" # $option comes from select_fun_facts()
        echo "Removing Fun Fact! ... OK" && sleep 0.25
        remove_fun_fact
    fi
}


function validate_splash() {
    [[ -z "$1" ]] && return 0

    if [[ ! -f "$1" ]]; then
        local error_message
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            error_message="'$1' file not found!"
        else
            error_message="ERROR: '$1' file not found!"
        fi
        echo "$error_message" #>&2
        [[ "$CONFIG_FLAG" -eq 1 ]] && echo "Check the 'splashscreen_path' value in '$SCRIPT_CFG'" #>&2
        return 1
    fi
}


function validate_color() {
    [[ -z "$1" ]] && return 0

    if convert -list color | grep -q "^$1\b"; then
        return 0
    else
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            echo "Invalid color '$1'."
            return 1
        else
            echo "ERROR: Invalid color '$1'." >&2
            [[ "$CONFIG_FLAG" -eq 1 ]] && echo "Check the 'text_color' value in '$SCRIPT_CFG'" >&2
            echo >&2
            echo "Short list of available colors:" >&2
            echo "-------------------------------" >&2
            echo "black white gray gray10 gray25 gray50 gray75 gray90" >&2
            echo "pink red orange yellow green silver blue cyan purple brown" >&2
            echo >&2
            echo "TIP: run the 'convert -list color' command to get a full list." >&2
            exit 1
        fi
    fi
}

function validate_boot_script() {
    [[ -z "$1" ]] && return 0

    if [[ "$1" != "false" && "$1" != "true" ]]; then
        echo "ERROR: Invalid boolean '$1'" >&2
        echo "Check the 'boot_script' value in '$SCRIPT_CFG'" >&2
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
    while true; do
        check_config > /dev/null
    
        version="$SCRIPT_VERSION"
        last_commit="$(get_last_commit)"

        check_apply_splash
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
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

        if [[ "$SCRIPT_DIR" == "/opt/retropie/supplementary/fun-facts-splashscreens" ]]; then # If script is used as a scriptmodule
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
            8 "$option_updates"
            9 "Reset config"
        )
        
        dialog_height=18
        dialog_width=60
        menu_items="${#options[@]}"
        
        cmd=(dialog \
            --backtitle "$SCRIPT_TITLE"
            --title "Fun Facts! Splashscreens" \
            --cancel-label "Exit" \
            --menu "Version: $version\nLast commit: $last_commit" "$dialog_height" "$dialog_width" "$menu_items")

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
                            12 "$dialog_width" 2>&1 >/dev/tty)"

                    result_value="$?"
                    if [[ "$result_value" == "$DIALOG_OK" ]]; then
                        validation="$(validate_splash "$splash")"
                        if [[ -n "$validation" ]]; then
                            dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --title "Error!" \
                                --msgbox "$validation" 8 "$dialog_width" 2>&1 >/dev/tty
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
                                --msgbox "'splashscreen_path' set to '$SPLASH_PATH'" 8 "$dialog_width" 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                2)
                    CONFIG_FLAG=0

                    cmd=(dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --title "Set text color" \
                        --cancel-label "Back" \
                        --menu "Choose an option" "$dialog_height" "$dialog_width" "$menu_items")

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
                                    --menu "Choose a color" "$dialog_height" "$dialog_width" "${#color_list[@]}")

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
                                            --msgbox "$validation" 8 "$dialog_width" 2>&1 >/dev/tty
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
                                            --msgbox "Text color set to '$TEXT_COLOR'" 8 "$dialog_width" 2>&1 >/dev/tty
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
                                            --msgbox "Text color set to '$TEXT_COLOR'" 8 "$dialog_width" 2>&1 >/dev/tty
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
                        --inputbox "Enter a new Fun Fact!" 8 "$dialog_width" 2>&1 >/dev/tty)"

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
                                --msgbox "$validation" 8 "$dialog_width" 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                4)                    
                    local validation
                    validation="$(check_fun_facts_txt)"
                    if [[ -n "$validation" ]]; then
                        dialog \
                            --backtitle "$SCRIPT_TITLE" \
                            --title "Error!" \
                            --msgbox "$validation" 8 "$dialog_width" 2>&1 >/dev/tty
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
                            --menu "Choose a Fun Fact! to remove" "$dialog_height" "$dialog_width" "${#fun_facts[@]}")

                        choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
                        result_value="$?"
                        if [[ "$result_value" == "$DIALOG_OK" ]]; then
                            local fun_fact
                            fun_fact="${options[$((choice*2-1))]}"
                            remove_fun_fact "$fun_fact" \
                            && dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --title "Success!" \
                                --msgbox "'$fun_fact' succesfully removed!" 8 "$dialog_width" 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                5)
                    local validation
                    validation="$(check_fun_facts_txt)"
                    if [[ -n "$validation" ]]; then
                        dialog \
                            --backtitle "$SCRIPT_TITLE" \
                            --msgbox "$validation" 7 50 2>&1 >/dev/tty
                    else
                        create_fun_fact
                    fi
                    ;;
                6)
                    if [[ ! -f "$RESULT_SPLASH" ]]; then
                        dialog \
                            --backtitle "$SCRIPT_TITLE" \
                            --msgbox "ERROR: create a Fun Facts! splashscreen before applying it." 7 50 2>&1 >/dev/tty
                    else
                        apply_splash
                    fi
                    ;;
                7)
                    check_boot_script
                    return_value="$?"
                    if [[ "$return_value" -eq 0 ]]; then
                        if disable_boot_script; then
                            set_config "boot_script" "false" > /dev/null
                            local output="Fun Facts! Splashscreens script DISABLED at boot."
                         else
                            local output="ERROR: failed to DISABLE Fun Facts! Splashscreens script at boot."
                        fi
                    else
                        if enable_boot_script; then
                            set_config "boot_script" "true" > /dev/null
                            local output="Fun Facts! Splashscreens script ENABLED at boot."
                         else
                            local output="ERROR: failed to ENABLE Fun Facts! Splashscreens script at boot."
                        fi
                    fi
                    dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --msgbox "\n$output\n" 7 55 2>&1 >/dev/tty
                    ;;
                8)
                    if [[ "$SCRIPT_DIR" == "/opt/retropie/supplementary/fun-facts-splashscreens" ]]; then # If script is used as a scriptmodule
                        dialog \
                            --backtitle "$SCRIPT_TITLE" \
                            --msgbox "Can't update the script when using it from RetroPie-Setup.\n\nGo to:\n -> Manage packages\n -> Manage experimental packages\n -> fun-facts-splashscreens\n -> Update from source" 12 50 2>&1 >/dev/tty
                    else
                        if [[ "$updates_status" == "needs-to-pull" ]]; then
                            git pull && chown -R "$user":"$user" .
                        else
                            dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --msgbox "\nFun Facts! Splashscreens is $updates_output!\n" 7 50 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                9)
                    reset_config
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

    while [[ -n "$1" ]]; do
        case "$1" in
#H --help                                   Print the help message and exit.
            --help)
                echo
                echo "$SCRIPT_TITLE"
                echo "$SCRIPT_DESCRIPTION"
                echo
                echo "USAGE: sudo $0 [OPTIONS]"
                echo
                echo "OPTIONS:"
                echo
                sed '/^#H /!d; s/^#H //' "$0"
                echo
                exit 0
                ;;
#H --splash-path [path/to/splashscreen]     Set which splashscreen to use.
            --splash-path)
                check_argument "$1" "$2" || exit 1
                shift
                CONFIG_FLAG=0
                validate_splash "$1" || exit 1
                SPLASH_PATH="$1"
                set_config "splashscreen_path" "$SPLASH_PATH"
                ;;
#H --text-color [color]                     Set which text color to use.
            --text-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_color "$1"
                return_value="$?"
                if [[ "$return_value" != 1 ]]; then
                    TEXT_COLOR="$1"
                    set_config "text_color" "$TEXT_COLOR"
                fi
                ;;
#H --add-fun-fact                           Add a new Fun Fact!.
            --add-fun-fact)
                check_argument "$1" "$2" || exit 1
                shift
                add_fun_fact "$1"
                ;;
#H --remove-fun-fact                        Remove a Fun Fact!.
            --remove-fun-fact)
                check_fun_facts_txt
                remove_fun_fact
                ;;
#H --create-fun-fact                        Create a new Fun Facts! splashscreen.
            --create-fun-fact)
                check_fun_facts_txt
                CREATE_SPLASH_FLAG=1
                ;;
#H --apply-splash                           Apply Fun Facts! splashscreen.
            --apply-splash)
                if [[ ! -f "$RESULT_SPLASH" ]]; then
                    echo >&2
                    echo "ERROR: Create a Fun Facts! splashscreen before applying it." >&2
                    echo >&2
                    echo "Try 'sudo $0 --help' for more info." >&2
                    echo >&2
                    exit 1
                else
                    apply_splash
                fi
                ;;
#H --enable-boot                            Enable script to be launch at boot.
            --enable-boot)
                ENABLE_BOOT_FLAG=1
                ;;
#H --disable-boot                           Disable script to be launch at boot.
            --disable-boot)
                DISABLE_BOOT_FLAG=1
                ;;
#H --gui                                    Start GUI.
            --gui)
                GUI_FLAG=1
                ;;
#H --reset-config                           Reset config file.
            --reset-config)
                RESET_CONFIG_FLAG=1
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
            *)
                echo >&2
                echo "ERROR: Invalid option '$1'" >&2
                echo >&2
                echo "Try 'sudo $0 --help' for more info." >&2
                echo >&2
                exit 2
                ;;
        esac
        shift
    done
}

function main() {
    if ! is_retropie; then
        echo "ERROR: RetroPie is not installed. Aborting ..." >&2
        exit 1
    fi

    check_dependencies

    # check if sudo is used.
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "ERROR: Script must be run under sudo." >&2
        usage
        exit 1
    fi
    
    mkdir -p "$RP_DIR/splashscreens"
    
    get_options "$@"

    if [[ "$RESET_CONFIG_FLAG" -eq 1 ]]; then
        reset_config
    else
        check_config > /dev/null
    fi

    if [[ "$CREATE_SPLASH_FLAG" -eq 1 ]]; then
        create_fun_fact
    fi

    if [[ "$ENABLE_BOOT_FLAG" -eq 1 ]]; then
        if enable_boot_script; then
            set_config "boot_script" "true" > /dev/null
            echo "Fun Facts! Splashscreens script ENABLED at boot."
        else
            echo "ERROR: failed to ENABLE Fun Facts! Splashscreens script at boot." >&2
        fi
    fi

    if [[ "$DISABLE_BOOT_FLAG" -eq 1 ]]; then
        if disable_boot_script; then
            set_config "boot_script" "false" > /dev/null
            echo "Fun Facts! Splashscreens script DISABLED at boot."
        else
            echo "ERROR: failed to DISABLE Fun Facts! Splashscreens script at boot." >&2
        fi
    fi

    if [[ "$GUI_FLAG" -eq 1 ]]; then
        gui
    fi
}

main "$@"
