#!/bin/bash
# Save evidence screenshots into ../screenshots
#   snap.sh <name>   -> captures the Terminal window this script is running in
DIR="$(cd "$(dirname "$0")/.." && pwd)/screenshots"
mkdir -p "$DIR"
TTY="$(tty)"
WID=$(osascript -e "tell application \"Terminal\" to id of first window whose tty of selected tab is \"$TTY\"" 2>/dev/null)
[ -z "$WID" ] && WID=$(osascript -e 'tell application "Terminal" to id of front window')
sleep 0.5
screencapture -x -o -l "$WID" "$DIR/$1.png"
echo "saved screenshots/$1.png"
