#!/usr/bin/env bash
# imagemagick.sh

function IM_add_background() {
    convert -size "$screen_w"x"$screen_h" xc:"$bg_color" \
        "$TMP_DIR/$TMP_SPLASHSCREEN"

    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        return 0
    else
        log "ERROR: Imagemagick - Adding background ... failed!"
        ERRORS=$(($ERRORS + 1))
        return 1
    fi
}


function IM_convert_svg_to_png() {    
    convert "$logo" "$TMP_DIR/$system.png"
    
    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        return 0
    else
        log "ERROR: Imagemagick - SVG to PNG conversion ... failed!"
        ERRORS=$(($ERRORS + 1))
        return 1
    fi
}


function IM_resize_logo() {    
    if get_boxart > /dev/null || get_console > /dev/null; then
        local size_y="$(((screen_h*10/100)))"
    else
        local size_y="$(((screen_h*25/100)))"
    fi
    
    convert -background none \
        -scale "$(((screen_w*60/100)))"x"$size_y" \
        "$logo" "$TMP_DIR/$system.png"

    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        return 0
    else
        log "ERROR: Imagemagick - Logo resizing ... failed!"
        ERRORS=$(($ERRORS + 1))
        return 1
    fi
}


function IM_add_logo() {
    if file --mime-type "$logo" | grep -q "svg"; then
        IM_convert_svg_to_png
    elif file --mime-type "$logo" | grep -q "png" || file --mime-type "$logo" | grep -q "jpeg"; then
        cp "$logo" "$TMP_DIR/$system.png"
    else
        file --mime-type "$logo"
        log "ERROR: Imagemagick - File type not recognised!"
        exit 1
    fi
    
    IM_resize_logo
    
    if get_boxart > /dev/null || get_console > /dev/null; then
        local gravity="north"
        local offset_y="$(((screen_h*5/100)))"
    else
        local gravity="center"
        local image_h
        image_h="$(identify -format "%h" "$TMP_DIR/$system.png")"
        image_h="$(((image_h/2)))"
        local offset_y="-$image_h"
    fi
    
    convert "$TMP_DIR/$TMP_SPLASHSCREEN" \
        "$TMP_DIR/$system.png" \
        -gravity "$gravity" \
        -geometry +0+"$offset_y" \
        -composite \
        "$TMP_DIR/$TMP_SPLASHSCREEN"

    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        return 0
    else
        log "ERROR: Imagemagick - Adding '$system' logo image ... failed!"
        ERRORS=$(($ERRORS + 1))
        return 1
    fi
}


function IM_add_boxart() {
    local boxart
    boxart="$(get_boxart)"
    convert "$TMP_DIR/$TMP_SPLASHSCREEN" \
        \( "$boxart" -scale x"$(((screen_h*45/100)))" \) \
        -gravity center \
        -geometry +0-"$(((screen_h*(10-(5/2))/100)))" \
        -composite \
        "$TMP_DIR/$TMP_SPLASHSCREEN"

    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        return 0
    else
        log "ERROR: Imagemagick - Adding boxart image ... failed!"
        ERRORS=$(($ERRORS + 1))
        return 1
    fi
}


function IM_add_console() {
    local console
    console="$(get_console)"
    convert "$TMP_DIR/$TMP_SPLASHSCREEN" \
        \( "$console" -scale x"$(((screen_h*45/100)))" \) \
        -gravity center \
        -geometry +0-"$(((screen_h*(10-(5/2))/100)))" \
        -composite \
        "$TMP_DIR/$TMP_SPLASHSCREEN"

    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        return 0
    else
        log "ERROR: Imagemagick - Adding '$system' console image ... failed!"
        ERRORS=$(($ERRORS + 1))
        return 1
    fi
}


function IM_add_fun_fact() {
    local random_fact
    random_fact="$(shuf -n 1 "$FUN_FACTS_TXT")"
    
    convert "$TMP_DIR/$TMP_SPLASHSCREEN" \
        -size "$(((screen_w*75/100)))"x"$(((screen_h*15/100)))" \
        -background none \
        -fill "$text_color" \
        -interline-spacing 2 \
        -font "$font" \
        -gravity south \
        caption:"$random_fact" \
        -geometry +0+"$(((screen_h*15/100)))" \
        -composite \
        "$TMP_DIR/$TMP_SPLASHSCREEN"

    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        return 0
    else
        log "ERROR: Imagemagick - Adding 'Fun Fact!' ... failed!"
        ERRORS=$(($ERRORS + 1))
        return 1
    fi
}


function IM_add_press_button_text() {
    convert "$TMP_DIR/$TMP_SPLASHSCREEN" \
        -fill "$press_button_text_color" \
        -interline-spacing 2 \
        -font "$font" \
        -pointsize 16 \
        -gravity south \
        -annotate +0+"$(((screen_h*5/100)))" "${press_button_text^^}" \
        "$TMP_DIR/$TMP_SPLASHSCREEN"

    local return_value="$?"
    if [[ "$return_value" -eq 0 ]]; then
        return 0
    else
        log "ERROR: Imagemagick - Adding 'Press button text' ... failed!"
        ERRORS=$(($ERRORS + 1))
        return 1
    fi
}
