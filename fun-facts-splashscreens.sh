#!/usr/bin/env bash
# fun-facts-splashscreens.sh
#
# Fun Facts! splashscreens for RetroPie.
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

home="$(find /home -type d -name RetroPie -print -quit 2>/dev/null)"
home="${home%/RetroPie}"

readonly RP_DIR="$home/RetroPie"
readonly ES_THEMES_DIR="/etc/emulationstation/themes"
readonly SPLASH_LIST="/etc/splashscreen.list"
readonly RCLOCAL="/etc/rc.local"

readonly SCRIPT_VERSION="1.4.1"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_CFG="$SCRIPT_DIR/fun-facts-settings.cfg"
readonly SCRIPT_TITLE="Fun Facts! splashscreens for RetroPie"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to create splashscreens with random video game related fun facts."

# Variables ############################################

readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun-facts.txt"
readonly RESULT_SPLASH="$RP_DIR/splashscreens/fun-facts-splashscreen.png"
readonly DEFAULT_SPLASH="$SCRIPT_DIR/default-splashscreen.png"
readonly DEFAULT_COLOR="white"

SPLASH_PATH=
TEXT_COLOR=
ENABLE_BOOT_FLAG=0
DISABLE_BOOT_FLAG=0
CONFIG_FLAG=0
GUI_FLAG=0


# Functions ############################################

function is_retropie() {
    [[ -d "$RP_DIR" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}


function check_dependencies() {
    if ! which convert > /dev/null; then
        echo "ERROR: The imagemagick package is not installed!" >&2
        echo "Please, install it with 'sudo apt-get install imagemagick'." >&2
        exit 1
    fi
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

    if [[ "$GUI_FLAG" -eq 0 ]]; then
        echo "'$1' set to '$2'."
    fi
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

    [[ "$GUI_FLAG" -eq 0 ]] && echo  -e "\nChecking config ..."

    SPLASH_PATH="$(get_config "splashscreen_path")"
    TEXT_COLOR="$(get_config "text_color")"

    if [[ -z "$SPLASH_PATH" ]]; then
        SPLASH_PATH="$DEFAULT_SPLASH"
        [[ "$GUI_FLAG" -eq 0 ]] && echo "No 'splashscreen_path' set. Switching to defaults ..."
    fi
    if [[ -z "$TEXT_COLOR" ]]; then
        TEXT_COLOR="$DEFAULT_COLOR"
        [[ "$GUI_FLAG" -eq 0 ]] && echo  -e "No 'text_color' set. Switching to defaults ..."
    fi

    validate_splash "$SPLASH_PATH"
    validate_color "$TEXT_COLOR"

    if [[ "$GUI_FLAG" -eq 0 ]]; then
        echo
        echo "'splashscreen_path'   = '$SPLASH_PATH'"
        echo "'text_color'          = '$TEXT_COLOR'"
    fi
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

    [[ -f "$splash" ]] || splash="$DEFAULT_SPLASH"
    [[ -n "$color" ]] || color="$DEFAULT_COLOR"

    random_fact="$(shuf -n 1 "$FUN_FACTS_TXT")"

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
    && [[ "$GUI_FLAG" -eq 1 ]] && dialog --backtitle "$SCRIPT_TITLE" --msgbox "\nFun Facts! splashscreen successfully created!\n" 7 50 2>&1 || echo "Fun Facts! splashscreen successfully created!"
}


function validate_splash() {
    [[ -z "$1" ]] && return 0

    if [[ ! -f "$1" ]]; then
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            if [[ "$CONFIG_FLAG" -eq 1 ]]; then
                echo "ERROR: check the 'splashscreen_path' value in '$SCRIPT_CFG'"
            else
                echo "ERROR: '$1' file not found!"
            fi
            return 1
        else
            echo >&2
            echo "ERROR: '$1' file not found!" >&2
            if [[ "$CONFIG_FLAG" -eq 1 ]]; then
                echo "Check the 'splashscreen_path' value in '$SCRIPT_CFG'" >&2
            fi
            echo >&2
            exit 1
        fi
    fi
}


function validate_color() {
    [[ -z "$1" ]] && return 0

    if convert -list color | grep -q "^$1\b"; then
        return 0
    else
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            if [[ "$CONFIG_FLAG" -eq 1 ]]; then
                echo "ERROR: check the 'text_color' value in '$SCRIPT_CFG'"
            else
                echo "ERROR: invalid color '$1'."
            fi
            return 1
        else
            echo >&2
            echo "ERROR: invalid color '$1'." >&2
            if [[ "$CONFIG_FLAG" -eq 1 ]]; then
                echo "Check the 'text_color' value in '$SCRIPT_CFG'" >&2
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
        fi
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
    check_config

    while true; do
        local last_commit="$(get_last_commit)"

        cmd=(dialog \
            --backtitle "$SCRIPT_TITLE"
            --title "Fun Facts! Splashscreens" \
            --cancel-label "Exit" \
            --menu "Version: $SCRIPT_VERSION\nLast commit: $last_commit" 15 60 8)

        option_splash="Set splashscreen path (default: $DEFAULT_SPLASH)"
        [[ -n "$SPLASH_PATH" ]] && option_splash="Set splashscreen path ($SPLASH_PATH)"

        option_color="Set text color (default: $DEFAULT_COLOR)"
        [[ -n "$TEXT_COLOR" ]] && option_color="Set text color ($TEXT_COLOR)"

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
            1 "$option_splash"
            2 "$option_color"
            3 "Create a new Fun Facts! splashscreen"
            4 "$option_apply_splash"
            5 "Enable/Disable script at boot ($option_boot)"
            6 "$option_updates"
        )

        choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    CONFIG_FLAG=0
                    splash="$(dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --title "Set splashscreen path" \
                        --cancel-label "Back" \
                        --inputbox "Enter path to splashscreen... \n\n(If input is left empty, default splashscreen will be used)" 12 60 2>&1 >/dev/tty)"

                    result_value="$?"
                    if [[ "$result_value" -eq 0 ]]; then
                        local validation="$(validate_splash "$splash")"

                        if [[ -n "$validation" ]]; then
                            dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --msgbox "$validation" 10 50 2>&1 >/dev/tty
                        else
                            if [[ -z "$splash" ]]; then
                                SPLASH_PATH="$DEFAULT_SPLASH"
                            else
                                SPLASH_PATH="$splash"
                            fi
                            set_config "splashscreen_path" "$splash"
                            dialog \
                                --backtitle "$SCRIPT_TITLE" \
                                --msgbox "'splashscreen_path' set to '$SPLASH_PATH'" 10 50 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                2)
                    CONFIG_FLAG=0

                    cmd=(dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --title "Set text color" \
                        --cancel-label "Back" \
                        --menu "Choose an option" 15 60 8)

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
                                    --menu "Choose a color" 15 60 "${#color_list[@]}")

                                choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
                                result_value="$?"
                                if [[ "$result_value" -eq 0 ]]; then
                                    if [[ "$choice" -eq 1 ]]; then
                                        local color=""
                                    else
                                        local color="${options[$((choice*2-1))]}"
                                    fi

                                    local validation="$(validate_color $color)"

                                     if [[ -n "$validation" ]]; then
                                        dialog \
                                            --backtitle "$SCRIPT_TITLE" \
                                            --msgbox "$validation" 6 40 2>&1 >/dev/tty
                                    else
                                        if [[ -z "$color" ]]; then
                                            TEXT_COLOR="$DEFAULT_COLOR"
                                            set_config "text_color" ""
                                        else
                                            TEXT_COLOR="$color"
                                            set_config "text_color" "$TEXT_COLOR"
                                        fi
                                        dialog \
                                            --backtitle "$SCRIPT_TITLE" \
                                            --msgbox "\nText color set to '$TEXT_COLOR'" 7 50 2>&1 >/dev/tty
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
                                if [[ "$result_value" -eq 0 ]]; then
                                    local color="${options[$((choice*2-1))]}"

                                    local validation="$(validate_color $color)"

                                     if [[ -n "$validation" ]]; then
                                        dialog \
                                            --backtitle "$SCRIPT_TITLE" \
                                            --msgbox "$validation" 6 40 2>&1 >/dev/tty
                                    else
                                        if [[ -z "$color" ]]; then
                                            TEXT_COLOR="$DEFAULT_COLOR"
                                            set_config "text_color" ""
                                        else
                                            TEXT_COLOR="$color"
                                            set_config "text_color" "$TEXT_COLOR"
                                        fi
                                        dialog \
                                            --backtitle "$SCRIPT_TITLE" \
                                            --msgbox "\nText color set to '$TEXT_COLOR'" 7 50 2>&1 >/dev/tty
                                    fi
                                fi
                                ;;
                        esac
                    else
                        break
                    fi
                    ;;
                3)
                    check_config
                    create_fun_fact
                    ;;
                4)
                    if [[ ! -f "$RESULT_SPLASH" ]]; then
                        dialog \
                            --backtitle "$SCRIPT_TITLE" \
                            --msgbox "ERROR: create a Fun Facts! splashscreen before applying it." 7 50 2>&1 >/dev/tty
                    else
                        apply_splash
                    fi
                    ;;
                5)
                    check_boot_script
                    return_value="$?"
                    if [[ "$return_value" -eq 0 ]]; then
                        disable_boot_script && local output="Fun Facts! Splashscreens script DISABLED at boot." || local output="ERROR: failed to DISABLE Fun Facts! Splashscreens script at boot."
                    else
                        check_config
                        enable_boot_script && local output="Fun Facts! Splashscreens script ENABLED at boot." || local output="ERROR: failed to ENABLE Fun Facts! Splashscreens script at boot."
                    fi
                    dialog \
                        --backtitle "$SCRIPT_TITLE" \
                        --msgbox "\n$output\n" 7 55 2>&1 >/dev/tty
                    ;;
                6)
                    if [[ "$SCRIPT_DIR" == "/opt/retropie/supplementary/fun-facts-splashscreens" ]]; then # If script is used as a scriptmodule
                        dialog \
                            --backtitle "$SCRIPT_TITLE" \
                            --msgbox "Can't update the script when using it from RetroPie-Setup.\n\nGo to:\n -> Manage packages\n -> Manage experimental packages\n -> fun-facts-splashscreens\n -> Update from source" 12 50 2>&1 >/dev/tty
                    else
                        if [[ "$updates_status" == "needs-to-pull" ]]; then
                            git pull
                        else
                            :
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

    while [[ -n "$1" ]]; do
        case "$1" in
#H -h, --help                                   Print the help message and exit.
            -h|--help)
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

#H -s, --splash-path [path/to/splashscreen]     Set which splashscreen to use.
            -s|--splash-path)
                check_argument "$1" "$2" || exit 1
                shift
                validate_splash "$1"
                return_value="$?"
                if [[ "$return_value" != 1 ]]; then
                    SPLASH_PATH="$1"
                    set_config "splashscreen_path" "$SPLASH_PATH"
                fi
                ;;

#H -t, --text-color [color]                     Set which text color to use.
            -t|--text-color)
                check_argument "$1" "$2" || exit 1
                shift
                validate_color "$1"
                return_value="$?"
                if [[ "$return_value" != 1 ]]; then
                    TEXT_COLOR="$1"
                    set_config "text_color" "$TEXT_COLOR"
                fi
                ;;

#H -c, --create-fun-fact                        Create a new Fun Facts! splashscreen.
            -c|--create-fun-fact)
                CREATE_SPLASH_FLAG=1
                ;;

#H -a, --apply-splash                           Apply Fun Facts! splashscreen.
            -a|--apply-splash)
                if [[ ! -f "$RESULT_SPLASH" ]]; then
                    echo >&2
                    echo "ERROR: create a Fun Facts! splashscreen before applying it." >&2
                    echo >&2
                    echo "Try 'sudo $0 --help' for more info." >&2
                    echo >&2
                    exit 1
                else
                    apply_splash
                fi
                ;;

#H -e, --enable-boot                            Enable script to be launch at boot.
            -e|--enable-boot)
                ENABLE_BOOT_FLAG=1
                ;;

#H -d, --disable-boot                           Disable script to be launch at boot.
            -d|--disable-boot)
                DISABLE_BOOT_FLAG=1
                ;;

#H -g, --gui                                    Start GUI.
            -g|--gui)
                GUI_FLAG=1
                ;;

#H -u, --update                                 Update script.
            -u|--update)
                check_updates
                if [[ "$updates_status" == "needs-to-pull" ]]; then
                    git pull
                fi
                ;;
#H -v, --version                            Check script version.
            -v|--version)
                echo "$SCRIPT_VERSION"
                ;;
            *)
                echo "ERROR: invalid option '$1'" >&2
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

    if [[ "$CREATE_SPLASH_FLAG" -eq 1 ]]; then
        check_config
        create_fun_fact
    fi

    if [[ "$ENABLE_BOOT_FLAG" -eq 1 ]]; then
        check_config
        enable_boot_script || echo "ERROR: failed to enable Fun Facts! script at boot." >&2
    fi

    if [[ "$DISABLE_BOOT_FLAG" -eq 1 ]]; then
        disable_boot_script || echo "ERROR: failed to disable Fun Facts! script at boot." >&2
    fi

    if [[ "$GUI_FLAG" -eq 1 ]]; then
        gui
    fi
}

main "$@"
