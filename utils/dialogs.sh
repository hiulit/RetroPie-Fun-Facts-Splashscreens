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
    
    local text_color="$(get_config "${property}_text_color")"
    if [[ -n "$text_color" ]]; then
        option_text_color="Text color ($text_color)"
    else
        option_text_color="Text color"
    fi
    
    local text_font_path="$(get_config "${property}_text_font_path")"
    if [[ -n "$text_font_path" ]]; then
        option_text_font_path="Text font ($text_font_path)"
    else
        option_text_font_path="Text font"
    fi
    
    options=(
        1 "Background"
        2 "$option_text_color"
        3 "$option_text_font_path"
    )
    if [[ "$property" == "launching_images" ]]; then
        local press_button_text="$(get_config "${property}_press_button_text")"
        if [[ -n "$press_button_text" ]]; then
            option_press_button_text="'Press a button' text ($press_button_text)"
        else
            option_press_button_text="'Press a button' text"
        fi
        
        local press_button_text_color="$(get_config "${property}_press_button_text_color")"
        if [[ -n "$press_button_text_color" ]]; then
            option_press_button_text_color="'Press a button' text color ($press_button_text_color)"
        else
            option_press_button_text_color="'Press a button' text color"
        fi
        
        options+=(
            4 "$option_press_button_text"
            5 "$option_press_button_text_color"
        )
    fi
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
            4)
                dialog_choose_text "${property}_press_button" # Remove '_text' ?
                ;;
            5)
                dialog_choose_color "${property}_press_button_text"
                ;;
        esac
    else
        dialog_splashscreens_settings
    fi
}

function dialog_choose_text() {
    local property="$1"
    local property_var="${property^^}_TEXT"
    local property_text="${property//_/ }"
    text="$(dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
                    --title "Set $property_text text" \
                    --cancel-label "Back" \
                    --inputbox "Enter $property_text text.\n\nEnter 'default' to set the default text.\nLeave the input empty to unset the text." \
                    12 "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
    result_value="$?"
    if [[ "$result_value" -eq "$DIALOG_OK" ]]; then
        if [[ -z "$text" ]]; then
            dialog_title="Success!"
            dialog_text="${property_text^} path unset."
            set_config "${property}_text" "" > /dev/null
        elif [[ "$text" == "default" ]]; then
            dialog_title="Success!"
            declare "$property_var"="$DEFAULT_LAUNCHING_IMAGES_PRESS_BUTTON_TEXT"
            dialog_text="${property_text^} text set to '${!property_var}'."
            set_config "${property}_text" "${!property_var}" > /dev/null
        else
            declare "$property_var"="$text"
            dialog_title="Success!"
            dialog_text="${property_text^} text set to '${!property_var}'."
            set_config "${property}_text" "${!property_var}" > /dev/null
        fi
        dialog_msgbox "$dialog_title" "$dialog_text"
    fi
}


function dialog_choose_background() {
    local property="$1"
    local property_text="${property//_/ }"
    
    local image_path="$(get_config "${property}_path")"
    if [[ -n "$image_path" ]]; then
        option_image_path="Image ($image_path)"
    else
        option_image_path="Image"
    fi
    
    local solid_color="$(get_config "${property}_color")"
    if [[ -n "$solid_color" ]]; then
        option_solid_color="Solid color ($solid_color)"
    else
        option_solid_color="Solid color"
    fi
    
    options=(
        1 "$option_image_path"
        2 "$option_solid_color"
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
                    if [[ "$property" = *"press_button"* ]]; then
                        property="launching_images"
                        dialog_choose_splashscreen_settings "$property"
                    else
                        dialog_choose_splashscreen_settings "${property%_*}"
                    fi
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
                    if [[ "$property" = *"press_button"* ]]; then
                        property="launching_images"
                        dialog_choose_splashscreen_settings "$property"
                    else
                        dialog_choose_splashscreen_settings "${property%_*}"
                    fi
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
                                && dialog_msgbox "Success!" "'$fun_fact' Fun Fact! removed successfully!"
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
        2 "Launching images"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Create Fun Facts! splashscreens" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                create_fun_fact
                dialog_create_fun_facts_splashscreens
                ;;
            2)
                dialog_choose_launching_images
                ;;
        esac
    fi
}


function dialog_choose_launching_images() {
    options=(
        1 "System launching images"
        2 "Game launching images"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Create Fun Facts! launching images" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                dialog_choose_launching_images_system
                ;;
            2)
                dialog_choose_games
                ;;
        esac
    else
       dialog_create_fun_facts_splashscreens 
    fi
}


function dialog_choose_launching_images_system() {
    options=(
        1 "All systems"
        2 "Choose systems"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Create Fun Facts! launching images" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                create_fun_fact "all"
                dialog_choose_launching_images_system
                ;;
            2)
                dialog_choose_systems
                ;;
        esac
    else
        dialog_choose_launching_images
    fi
}

function dialog_choose_systems() {
    local systems
    local system
    local i=1
    options=()
    
    systems="$(get_all_systems)"
    IFS=" " read -r -a systems <<< "${systems[@]}"
    for system in "${systems[@]}"; do
        options+=("$i" "$system" off)
        ((i++))
    done
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Create Fun Facts! system    launching images" \
        --cancel-label "Back" \
        --checklist "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choices" ]]; then
        IFS=" " read -r -a choices <<< "${choices[@]}"
        for choice in "${choices[@]}"; do
            system="${options[choice*3-2]}"
            create_fun_fact "$system"
        done
        dialog_choose_launching_images_system
    else
        dialog_choose_launching_images_system
    fi
}

function dialog_choose_games() {
    local systems
    local system
    local i=1
    options=()
    
    for system in "$RP_ROMS_DIR/"*; do
        if [[ ! -L "$system" ]]; then # Filter out symlinks.
            if [[ $(ls -A "$system") ]]; then # Check if folder is NOT empty
                if [[ $(find "$system" -maxdepth 1 -type f -name "*.*") ]]; then # Check if file has extension
                    options+=("$i" "$(basename "$system")" off)
                    ((i++))
                fi
            fi
        fi
    done
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Create Fun Facts! game launching images" \
        --cancel-label "Back" \
        --checklist "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choices" ]]; then
        IFS=" " read -r -a choices <<< "${choices[@]}"
        for choice in "${choices[@]}"; do
            system="${options[choice*3-2]}"
            system_extensions="$(xmlstarlet sel -t -v \
                "/systemList/system[name=\"$system\"]/extension" \
                "/etc/emulationstation/es_systems.cfg")"
            IFS=" " read -r -a system_extensions <<< "$system_extensions"
            games=()
            for extension in "${system_extensions[@]}"; do
                game="$(find "$RP_ROMS_DIR/$system/" -maxdepth 1 -type f  -name "*$extension")"
                if [[ -n "$game" ]]; then
                    games+=("$game")
                fi
            done
            if [[ "${#games[@]}" -gt 0 ]]; then
                for game in "${games[@]}"; do
                    create_fun_fact "$system" "$game"
                done
            fi
        done
        dialog_choose_games
    else
        dialog_choose_launching_images
    fi
}

function dialog_automate_scripts() {
    if check_boot_splashscreen; then
        option_boot="enabled"
    else
        option_boot="disabled"
    fi
    if check_runcommand_onend; then
        option_launching="enabled"
    else
        option_launching="disabled"
    fi
    options=(
        1 "Enable/disable boot splashscreen ($option_boot)"
        2 "Enable/disable launching images ($option_launching)"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Automate scripts" \
        --cancel-label "Back" \
        --help-button \
        --help-label "Help" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                check_boot_splashscreen
                local return_value="$?"
                if [[ "$return_value" -eq 0 ]]; then
                    if disable_boot_splashscreen; then
                        set_config "boot_splashscreen_script" "false" > /dev/null
                     else
                        dialog_msgbox "Error!" "Failed to DISABLE script at boot."
                    fi
                else
                    if enable_boot_splashscreen; then
                        set_config "boot_splashscreen_script" "true" > /dev/null
                     else
                        dialog_msgbox "Error!" "Failed to ENABLE script at boot."
                    fi
                fi
                ;;
            2)
                check_runcommand_onend
                local return_value="$?"
                if [[ "$return_value" -eq 0 ]]; then
                    if disable_launching_images; then
                        set_config "launching_images_script" "false" > /dev/null
                    else
                        dialog_msgbox "Error!" "Failed to DISABLE launching images."
                    fi
                else
                    if enable_launching_images; then
                        set_config "launching_images_script" "true" > /dev/null
                    else
                        dialog_msgbox "Error!" "Failed to ENABLE launching images."
                    fi
                fi
                ;;
        esac
        dialog_automate_scripts
    fi
}


function dialog_configuration_file() {
    options=(
        1 "Edit configuration file"
        2 "Reset configuration file"
    )
    menu_items="$(((${#options[@]} / 2)))"
    menu_text="Choose an option."
    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Automate scripts" \
        --cancel-label "Back" \
        --menu "$menu_text" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" "$menu_items")
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    if [[ -n "$choice" ]]; then
        case "$choice" in
            1)
                edit_config
                ;;
            2)
                reset_config
                ;;
        esac
    fi
}