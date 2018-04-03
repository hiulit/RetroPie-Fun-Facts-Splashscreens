#!/usr/bin/env bash
# fun-facts-splashscreens-runcommand-onend.sh

readonly RP_CONFIG_DIR="/opt/retropie/configs"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SYSTEM="$1"
readonly ROM_PATH="$3"
readonly LAUNCHING="$RP_CONFIG_DIR/$SYSTEM/launching"

rm -f "$LAUNCHING.png" "$LAUNCHING.jpg"

sudo "$SCRIPT_DIR/fun-facts-splashscreens.sh" --create-fun-fact "$SYSTEM" "$ROM_PATH"
