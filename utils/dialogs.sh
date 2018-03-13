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

function dialog_splashscreen_settings() {
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
        dialog_splashscreen_settings
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
                        dialog \
                            --backtitle "$DIALOG_BACKTITLE" \
                            --title "Error!" \
                            --msgbox "$validation" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                    else
			declare "$property_var"="$color"
                        set_config "${property}_color" "${!property_var}" > /dev/null
                        dialog \
                            --backtitle "$DIALOG_BACKTITLE" \
                            --title "Success!" \
                            --msgbox "${property_text^} color set to '${!property_var}'" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
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
                        dialog \
                            --backtitle "$DIALOG_BACKTITLE" \
                            --title "Error!" \
                            --msgbox "$validation" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
                    else
                        if [[ -z "$color" ]]; then
                            declare "$property_var"="$DEFAULT_BOOT_SPLASHSCREEN_TEXT_COLOR"
                        else
                            declare "$property_var"="$color"
                        fi
                        set_config "${property}_color" "${!property_var}" > /dev/null
                        dialog \
                            --backtitle "$DIALOG_BACKTITLE" \
                            --title "Success!" \
                            --msgbox "${property_text^} color set to '${!property_var}'" 8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
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
            dialog_text="$property_text path unset."
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
        dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --title "$dialog_title" \
            --msgbox "$dialog_text"  8 "$DIALOG_WIDTH" 2>&1 >/dev/tty
    elif [[ "$result_value" -eq "$DIALOG_CANCEL" ]]; then
        if [[ "$file_type" == "image" ]]; then
            dialog_choose_background "$property"
        elif [[ "$file_type" == "font" ]]; then
            dialog_choose_splashscreen_settings "$property"
        fi
    fi
}