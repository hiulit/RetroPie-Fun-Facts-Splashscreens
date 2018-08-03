#!/usr/bin/env bash
# fun-facts-splashscreens-runcommand-onend.sh

home="$(find /home -type d -name RetroPie -print -quit 2> /dev/null)"
home="${home%/RetroPie}"

readonly RP_DIR="$home/RetroPie"
readonly RP_ROMS_DIR="$RP_DIR/roms"
readonly RP_CONFIG_DIR="/opt/retropie/configs"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SYSTEM="$1"
readonly ROM_PATH="$3"
readonly SYSTEM_LAUNCHING_IMAGE="$RP_CONFIG_DIR/$SYSTEM/launching.png"
readonly GAME_LAUNCHING_IMAGE="$RP_ROMS_DIR/$SYSTEM/images/$(basename "${ROM_PATH%.*}")-launching.png"

[[ -f "$SYSTEM_LAUNCHING_IMAGE" ]] && rm "$SYSTEM_LAUNCHING_IMAGE"
[[ -f "$GAME_LAUNCHING_IMAGE" ]] && rm "$GAME_LAUNCHING_IMAGE"

sudo "$SCRIPT_DIR/fun-facts-splashscreens.sh" --create-fun-fact "$SYSTEM" "$ROM_PATH"
