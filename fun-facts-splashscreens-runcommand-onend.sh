#!/usr/bin/env bash
# fun-facts-splashscreens-runcommand-onend.sh

readonly RP_CONFIG_DIR="/opt/retropie/configs"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SYSTEM="$1"

[[ -f "$RP_CONFIG_DIR/$SYSTEM/launching.png"  ]] && rm "$RP_CONFIG_DIR/$SYSTEM/launching.png"

"$SCRIPT_DIR/fun-facts-splashscreens.sh" --create-fun-fact "$SYSTEM" #> /dev/null
