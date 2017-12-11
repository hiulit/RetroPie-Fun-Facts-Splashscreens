#!/usr/bin/env bash

rp_module_id="fun-facts-splashscreens"
rp_module_desc="Generate splashscreens with random video game related fun facts."
rp_module_help="Follow the instructions on the dialogs to set the splashscreen and the text color to create a new Fun Facts! splashscreen."
rp_module_help="$rp_module_help\n\nSet \"Enable at boot\" to create a new Fun Facts! splashscreen automatically at each system boot."
rp_module_section="exp"
rp_module_flags="noinstclean !x86 !osmc !xbian !mali !kms"

function depends_fun-facts_splashscreens() {
    getDepends "imagemagick"
}

function sources_fun-facts-splashscreens() {
    gitPullOrClone "$md_build" "https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens.git"
}

function install_fun-facts-splashscreens() {
    md_ret_files=(
        'fun-facts-splashscreens.sh'
        'fun-facts.txt'
        'fun-facts-settings.cfg'
        'default-splashscreen.png'
    )
}

function gui_fun-facts-splashscreens() {
    bash "$md_inst/fun-facts-splashscreens.sh" --gui
}