#!/usr/bin/env bash
# dialogs.sh

# Variables ############################################

readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_ESC=255
readonly DIALOG_HEIGHT=20
readonly DIALOG_WIDTH=60
readonly DIALOG_BACKTITLE="$SCRIPT_TITLE"


# Functions ###########################################

function dialog_info() {
    [[ -z "$1" ]] && log "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" >&2 && exit 1
    dialog --infobox "$1" 8 "$DIALOG_WIDTH"
}

function dialog_msgbox() {
    [[ -z "$1" ]] && log "ERROR: '${FUNCNAME[0]}' needs a title as an argument!" >&2 && exit 1
    [[ -z "$2" ]] && log "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" >&2 && exit 1
    dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$1" \
        --ok-label "OK" \
        --msgbox "$2"  8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
}

function dialog_splashscreens_settings() {
    options=(
        1 "Boot splashscreen"
        2 "Launching images"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Splashscreens settings" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                dialog_choose_splashscreen_settings "boot_splashscreen"
                ;;
            2)
               dialog_choose_splashscreen_settings "launching_images"
               ;;
        esac
    fi
}


function dialog_choose_splashscreen_settings() {
    local property="$1"
    local property_text="${property//_/ }"
    options=(
        1 "Background"
        2 "Text color ($(get_config "${property}_text_color"))"
        3 "Text font ($(get_config "${property}_text_font_path"))"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "${property_text^} settings" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                dialog_choose_background "${property}_background"
                ;;
            2)
                dialog_choose_color "${property}_text"
                ;;
            3)
                dialog_choose_path "${property}_text_font" "font"
                ;;
        esac
    else
        dialog_splashscreens_settings
    fi
}


function dialog_choose_background() {
    local property="$1"
    local property_text="${property//_/ }"
    options=(
        1 "Image ($(get_config "${property}_path"))"
        2 "Solid color ($(get_config "${property}_color"))"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option.\n\nIf both options are set, 'Image' takes precedence over 'Solid color'."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "${property_text^} settings" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                dialog_choose_path "$property" "image"
                ;;
            2)
                dialog_choose_color "$property"
                ;;
        esac
    else
        dialog_choose_splashscreen_settings "${property%_*}"
    fi
}


function dialog_choose_color() {
    local property="$1"
    local property_var="${property^^}_COLOR"
    local property_text="${property//_/ }"
    options=(
        1 "Basic colors"
        2 "Full list of colors"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Set $property_text color" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                i=1
                color_list=(
                    "white" "black" "gray" "gray10" "gray25" "gray50" "gray75" "gray90" "pink" "red" "orange" "yellow" "green" "silver" "blue" "cyan" "purple" "brown"
                )
                options=()
                for color in "${color_list[@]}"; do
                    options+=("$i" "$color")
                    ((i++))
                done
                menu_items="$(((${#options[@]} / 2)))"
                menu_text="Choose a color."
                cmd=(dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
                    --title "Set $property_text color" \
                    --cancel-label "Back" \
                    --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
                choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
                result_value="$?"
                if [[ "$result_value" -eq "$DIALOG_OK" ]]; then
                    color="${options[$((choice*2-1))]}"
                    validation="$(validate_color "$color")"
                    if [[ -n "$validation" ]]; then
                        dialog_msgbox "Error!" "$validation"
                    else
                        declare "$property_var"="$color"
                        set_config "${property}_color" "${!property_var}" > /dev/null
                        dialog_msgbox "Success!" "${property_text^} color set to '${!property_var}'."
                    fi
                    dialog_choose_splashscreen_settings "${property%_*}"
                elif [[ "$result_value" -eq "$DIALOG_CANCEL" ]]; then
                    dialog_choose_color "$property"
                fi
                ;;
            2)
                i=1
                color_list=()
                options=()
                while IFS= read -r line; do
                    color_list+=("$line")
                done < <(convert -list color | grep "srgb" | grep -Eo "^[^ ]+")
                for color in "${color_list[@]}"; do
                    options+=("$i" "$color")
                    ((i++))
                done
                menu_items="$(((${#options[@]} / 2)))"
                menu_text="Choose a color."
                cmd=(dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
                    --title "Set $property_text color" \
                    --cancel-label "Back" \
                    --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
                choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
                result_value="$?"
                if [[ "$result_value" -eq "$DIALOG_OK" ]]; then
                    color="${options[$((choice*2-1))]}"
                    validation="$(validate_color $color)"
                    if [[ -n "$validation" ]]; then
                        dialog_msgbox "Error!" "$validation"
                    else
                        if [[ -z "$color" ]]; then
                            declare "$property_var"="$DEFAULT_BOOT_SPLASHSCREEN_TEXT_COLOR"
                        else
                            declare "$property_var"="$color"
                        fi
                        set_config "${property}_color" "${!property_var}" > /dev/null
                        dialog_msgbox "Success!" "${property_text^} color set to '${!property_var}'."
                    fi
                    dialog_choose_splashscreen_settings "${property%_*}"
                elif [[ "$result_value" -eq "$DIALOG_CANCEL" ]]; then
                    dialog_choose_color "$property"
                fi
                ;;
        esac
    else
        dialog_choose_splashscreen_settings "${property%_*}"
    fi
}


function dialog_choose_path() {
    local property="$1"
    local property_var="${property^^}_PATH"
    local property_text="${property//_/ }"
    local file_type="$2"
    file_path="$(dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
                    --title "Set $property_text path" \
                    --cancel-label "Back" \
                    --inputbox "Enter $property_text path (must be an absolute path).\n\nEnter 'default' to set the default $file_type.\nLeave the input empty to unset the $file_type." \
                    12 "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
    result_value="$?"
    if [[ "$result_value" -eq "$DIALOG_OK" ]]; then
        if [[ -z "$file_path" ]]; then
            dialog_title="Success!"
            dialog_text="${property_text^} path unset."
            set_config "${property}_path" "" > /dev/null
        elif [[ "$file_path" == "default" ]]; then
            dialog_title="Success!"
            if [[ "$file_type" == "image" ]]; then
                declare "$property_var"="$DEFAULT_SPLASHSCREEN_BACKGROUND"
            elif [[ "$file_type" == "font" ]]; then
                declare "$property_var"="$(get_font)"
            fi
            dialog_text="${property_text^} path set to '${!property_var}'."
            set_config "${property}_path" "${!property_var}" > /dev/null
        else
            if [[ ! -f "$file_path" ]]; then
                dialog_title="Error!"
                dialog_text="'$file_path' file doesn't exist!"
            else
                declare "$property_var"="$file_path"
                dialog_title="Success!"
                dialog_text="${property_text^} path set to '${!property_var}'."
                set_config "${property}_path" "${!property_var}" > /dev/null
            fi
        fi
        dialog_msgbox "$dialog_title" "$dialog_text"
        if [[ "$file_type" == "image" ]]; then
            dialog_choose_background "$property"
        elif [[ "$file_type" == "font" ]]; then
            property="${property%_*}" # $property has too many '_', needed to remove the last one.
            dialog_choose_splashscreen_settings "${property%_*}"
        fi
    elif [[ "$result_value" -eq "$DIALOG_CANCEL" ]]; then
        if [[ "$file_type" == "image" ]]; then
            dialog_choose_background "$property"
        elif [[ "$file_type" == "font" ]]; then
            property="${property%_*}" # $property has too many '_', needed to remove the last one.
            dialog_choose_splashscreen_settings "${property%_*}"
        fi
    fi
}


function dialog_fun_facts_settings() {
    options=(
        1 "Add"
        2 "Remove"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Fun Facts! settings" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                new_fun_fact="$(dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
                    --title "Add a new Fun Fact!" \
                    --cancel-label "Back" \
                    --inputbox "Enter a new Fun Fact!" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
                result_value="$?"
                if [[ "$result_value" -eq "$DIALOG_OK" ]]; then
                    if [[ -z "$new_fun_fact" ]]; then
                        dialog_msgbox "Error!" "You must enter a Fun Fact!"
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
                            dialog_msgbox "$dialog_title" "$validation"
                        fi
                    fi
                    dialog_fun_facts_settings
                elif [[ "$result_value" -eq "$DIALOG_CANCEL" ]]; then
                    dialog_fun_facts_settings
                fi
                ;;
            2)
                while true; do
                    local validation
                    validation="$(is_fun_facts_empty)"
                    if [[ -n "$validation" ]]; then
                        dialog_msgbox "Error!" "$validation"
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
                                dialog_msgbox "Error!" "Can't remove a ghost Fun Fact!.\nTry removing it manually from '$FUN_FACTS_TXT'."
                            else
                                remove_fun_fact "$fun_fact" \
                                && dialog_msgbox "Success!" "'$fun_fact' succesfully removed!"
                            fi
                        else
                            dialog_fun_facts_settings
                            break
                        fi
                    fi
                done
                ;;
        esac
    fi
}


function dialog_create_fun_facts_splashscreens() {
    options=(
        1 "Boot splashscreen"
        2 "Launching image"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Create Fun Facts! Splashscreens" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                create_fun_fact
                ;;
            2)
                dialog_choose_launching_image
                ;;
        esac
    fi
}


function dialog_choose_launching_image() {
    options=(
        1 "System launching image"
        2 "Game launching image"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Create Fun Facts! Splashscreens" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                dialog_choose_launching_image_system
                ;;
            2)
                echo "game launching image"
                ;;
        esac
    fi
}


function dialog_choose_launching_image_system() {
    options=(
        1 "All systems"
        2 "Choose systems"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Create Fun Facts! Splashscreens" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                echo "all systems"
                ;;
            2)
                echo "choose systems"
                ;;
        esac
    fi
}


