#!/usr/bin/env bash

# Fun Facts! splashscreens for RetroPie.
# A tool for RetroPie to create splashscreens with random video game related fun facts.
#
# Requirements:
# - Retropie 4.x.x
# - Imagemagick package

home="$(find /home -type d -name RetroPie -print -quit 2>/dev/null)"
home="${home%/RetroPie}"

readonly ES_THEMES_DIR="/etc/emulationstation/themes"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly FUN_FACTS_CFG="$SCRIPT_DIR/fun-facts-settings.cfg"
readonly FUN_FACTS_TXT="$SCRIPT_DIR/fun-facts.txt"
readonly DEFAULT_SPLASH="$SCRIPT_DIR/default-splashscreen.png"
readonly DEFAULT_COLOR="white"
readonly RESULT_SPLASH="$home/RetroPie/splashscreens/fun-facts-splashscreen.png"
readonly RCLOCAL="/etc/rc.local"
readonly SPLASH_LIST="/etc/splashscreen.list"

SPLASH=
TEXT_COLOR=
ENABLE_BOOT_FLAG=0
DISABLE_BOOT_FLAG=0
CONFIG_FLAG=0
GUI_FLAG=0

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
        echo "ERROR: The imagemagick package is not installed!" >&2
        echo "Please, install it with 'sudo apt-get install imagemagick'." >&2
        exit 1
    fi
}

function set_config() {
    sed -i "s|^\($1\s*=\s*\).*|\1\"$2\"|" "$FUN_FACTS_CFG"

    if [[ "$GUI_FLAG" -eq 0 ]]; then
        echo "\"$1\" set to \"$2\"."
    fi
}

function get_config() {
    local config
    config="$(grep -Po "(?<=^$1 = ).*" "$FUN_FACTS_CFG")"
    config="${config%\"}"
    config="${config#\"}"
    echo "$config"
}

function check_config() {
    CONFIG_FLAG=1
    SPLASH="$(get_config splashscreen_path)"
    TEXT_COLOR="$(get_config text_color)"

    if [[ -z "$SPLASH" ]]; then
        if [[ "$GUI_FLAG" -eq 0 ]]; then
            echo
            echo "\"splashscreen_path\" is not defined in \"$FUN_FACTS_CFG\""
            echo "Switching to default splashscreen."
        fi
        SPLASH="$DEFAULT_SPLASH"
    fi

    if [[ -z "$TEXT_COLOR" ]]; then
        if [[ "$GUI_FLAG" -eq 0 ]]; then
            echo
            echo "\"text_color\" is not defined in \"$FUN_FACTS_CFG\""
            echo "Switching to default color."
        fi
        TEXT_COLOR="$DEFAULT_COLOR"
    fi

    validate_splash "$SPLASH"
    validate_color "$TEXT_COLOR"

    if [[ "$GUI_FLAG" -eq 0 ]]; then
        echo
        echo "\"splashscreen_path\" = \"$SPLASH\""
        echo "\"text_color\" = \"$TEXT_COLOR\""
    fi
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
                --backtitle "$backtitle" \
                --msgbox "\nFun Facts! splashscreen is already in use.\n" 7 50 2>&1 >/dev/tty
        else
            echo
            echo "Fun Facts! splashscreen is already in use."
        fi
    else
        echo "$RESULT_SPLASH" >"$SPLASH_LIST"
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            dialog \
                --backtitle "$backtitle" \
                --msgbox "\nFun Facts! splashscreen set succesfully!\n" 7 50 2>&1 >/dev/tty
        else
            echo "Fun Facts! splashscreen set succesfully!"
        fi
    fi
}

function enable_boot_script() {
    local command="\"$SCRIPT_DIR/$(basename "$0")\" --create-fun-fact \&"
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
            echo "ERROR: Unable to get the font from the \"$theme\" theme files." >&2
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

    if [[ "$GUI_FLAG" -eq 1 ]]; then
        dialog \
            --backtitle "$backtitle" \
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
    && [[ "$GUI_FLAG" -eq 1 ]] && dialog --backtitle "$backtitle" --msgbox "\nFun Facts! splashscreen successfully created!\n" 7 50 2>&1 || echo "Fun Facts! splashscreen successfully created!"
}

function validate_splash() {
    [[ -z "$1" ]] && return 0

    if [[ ! -f "$1" ]]; then
        if [[ "$GUI_FLAG" -eq 1 ]]; then
            if [[ "$CONFIG_FLAG" -eq 1 ]]; then
                echo "ERROR: check the \"splashscreen_path\" value in \"$FUN_FACTS_CFG\""
            else
                echo "ERROR: \"$1\" file not found!"
            fi

            return 1
        else
            echo >&2
            echo "ERROR: \"$1\" file not found!" >&2
            if [[ "$CONFIG_FLAG" -eq 1 ]]; then
                echo "Check the \"splashscreen_path\" value in \"$FUN_FACTS_CFG\"" >&2
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
                echo "ERROR: check the \"text_color\" value in \"$FUN_FACTS_CFG\""
            else
                echo "ERROR: invalid color \"$1\"."
            fi

            return 1
        else
            echo >&2
            echo "ERROR: invalid color \"$1\"." >&2
            if [[ "$CONFIG_FLAG" -eq 1 ]]; then
                echo "Check the \"text_color\" value in \"$FUN_FACTS_CFG\"" >&2
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

function check_argument() {
    # XXX: this method doesn't accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo >&2
        echo "ERROR: \"$1\" is missing an argument." >&2
        echo >&2
        echo "Try \"sudo $0 --help\" for more info." >&2
        echo >&2

        return 1
    fi
}

function check_updates() {
    echo "Let's see if there are any updates ..."
    git pull origin
}

function gui() {
    local backtitle="Fun Facts! Splashscreens for RetroPie"

    check_config

    while true; do
        cmd=(dialog \
            --backtitle "$backtitle"
            --title "Fun Facts! Splashscreens Config Menu" \
            --menu "Choose and option" 15 60 6)

        option_splash="Set splashscreen path (default: $DEFAULT_SPLASH)"
        [[ -n "$SPLASH" ]] && option_splash="Set splashscreen path ($SPLASH)"

        option_color="Set text color (default: $DEFAULT_COLOR)"
        [[ -n "$TEXT_COLOR" ]] && option_color="Set text color ($TEXT_COLOR)"

        check_apply_splash
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            option_apply_splash="Apply Fun Facts! splashscreen (already in use)"
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

        options=(
            1 "$option_splash"
            2 "$option_color"
            3 "Create a new Fun Facts! splashscreen"
            4 "$option_apply_splash"
            5 "Enable/Disable at boot ($option_boot)"
            6 "Update script"
        )

        choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

        result_value="$?"

        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    CONFIG_FLAG=0
                    splash="$(dialog \
                        --backtitle "$backtitle" \
                        --title "Set splashscreen path" \
                        --inputbox "Enter path to splashscreen... \n\n(If input is left empty, default splashscreen will be used)" 12 60 2>&1 >/dev/tty)"

                    result_value="$?"

                    if [[ "$result_value" -eq 0 ]]; then
                        local validation="$(validate_splash $splash)"

                        if [[ -n "$validation" ]]; then
                            dialog \
                                --backtitle "$backtitle" \
                                --msgbox "$validation" 10 50 2>&1 >/dev/tty
                        else
                            if [[ -z "$validation" ]]; then
                                SPLASH="$DEFAULT_SPLASH"
                                set_config "splashscreen_path" ""
                            else
                                SPLASH="$splash"
                                set_config "splashscreen_path" "$SPLASH"
                            fi
                            dialog \
                                --backtitle "$backtitle" \
                                --msgbox "Splashscreen path set to \"$SPLASH\"" 10 50 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                2)
                    CONFIG_FLAG=0
                    local i=1
                    local color_list=()
                    options=("$i" "default: white")

                    while IFS= read -r line; do
                        color_list+=("$line")
                    done < <(convert -list color | grep "srgb" | grep -Eo "^[^ ]+")

                    for color in "${color_list[@]}"; do
                        ((i++))
                        options+=("$i" "$color")
                        #~ ((i++))
                    done

                    cmd=(dialog \
                        --backtitle "$backtitle" \
                        --title "Set text color" \
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
                                --backtitle "$backtitle" \
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
                                --backtitle "$backtitle" \
                                --msgbox "\nText color set to \"$TEXT_COLOR\"" 7 50 2>&1 >/dev/tty
                        fi
                    fi
                    ;;
                3)
                    check_config
                    create_fun_fact
                    ;;
                4)
                    check_config
                    apply_splash
                    ;;
                5)
                    check_boot_script
                    return_value="$?"
                    if [[ "$return_value" -eq 0 ]]; then
                        disable_boot_script && local output="Fun Facts! script DISABLED at boot." || local output="ERROR: failed to DISABLE Fun Facts! script at boot."
                    else
                        check_config
                        enable_boot_script && local output="Fun Facts! script ENABLED at boot." || local output="ERROR: failed to ENABLE Fun Facts! script at boot."
                    fi
                    dialog \
                        --backtitle "$backtitle" \
                        --msgbox "\n$output\n" 7 40 2>&1 >/dev/tty
                    ;;
                6)
                    check_updates
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
                    SPLASH="$1"
                    set_config "splashscreen_path" "$SPLASH"
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
                check_config
                apply_splash
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
                ;;
            *)
                echo "ERROR: invalid option \"$1\"" >&2
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
        echo "ERROR: Script must be run under sudo." >&2
        usage
        exit 1
    fi

    if ! is_retropie; then
        echo "ERROR: RetroPie is not installed. Aborting ..." >&2
        exit 1
    fi

    mkdir -p "$home/RetroPie/splashscreens"

    get_options "$@"

    if [[ "$CREATE_SPLASH_FLAG" -eq 1 ]]; then
        check_config
        create_fun_fact "$SPLASH" "$TEXT_COLOR"
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
