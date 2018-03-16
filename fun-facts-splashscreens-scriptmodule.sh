#!/usr/bin/env bash

rp_module_id="fun-facts-splashscreens"
rp_module_desc="A tool for RetroPie to generate splashscreens with random video game related Fun Facts!."
rp_module_help="Basics:"
rp_module_help+="\n- Set splashscreen path"
rp_module_help+="\n- Set text color"
rp_module_help+="\n- Create a new Fun Facts! Splashscreen"
rp_module_help+="\n- Apply Fun Facts! Splashscreen"
rp_module_help+="\n\nExtras:"
rp_module_help+="\n- Set 'Enable at boot' to create a new Fun Facts! Splashscreen automatically at each system boot."
rp_module_help+="\n\nMore info at https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens"
rp_module_section="exp"
rp_module_flags="noinstclean !x86 !osmc !xbian !mali !kms"

function depends_fun-facts-splashscreens() {
    getDepends "imagemagick librsvg2-bin"
}

function sources_fun-facts-splashscreens() {
    gitPullOrClone "$md_build" "https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens.git"
}

function install_fun-facts-splashscreens() {
    md_ret_files=(
        'fun-facts-splashscreens.sh'
        'fun-facts-splashscreens-settings.cfg'
        'fun-facts-splashscreens-runcommand-onend.sh'
        'fun-facts.txt'
        'retropie-default.png'
        'utils/base.sh'
        'utils/dialogs.sh'
        'utils/imagemagick.sh'
    )
}

function gui_fun-facts-splashscreens() {
    bash "$md_inst/fun-facts-splashscreens.sh" --gui
}