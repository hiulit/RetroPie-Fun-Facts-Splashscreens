#!/usr/bin/env bash
# fun-facts-splashscreens-runcommand-onend.sh

home="$(find /home -type d -name RetroPie -print -quit 2> /dev/null)"
home="${home%/RetroPie}"

readonly RP_DIR="$home/RetroPie"
readonly RP_CONFIG_DIR="/opt/retropie/configs"

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

readonly SYSTEM="$1"

[[ -f "$RP_CONFIG_DIR/$SYSTEM/launching.png"  ]] && rm "$RP_CONFIG_DIR/$SYSTEM/launching.png"

"$SCRIPT_DIR/fun-facts-splashscreens.sh" --create-fun-fact "$SYSTEM" #> /dev/null

#~ mv "$RP_DIR/splashscreens/fun-facts-splashscreen.png" "$RP_CONFIG_DIR/$SYSTEM/launching.png"