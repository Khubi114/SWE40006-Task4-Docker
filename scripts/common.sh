#!/bin/bash
# Shared helpers: run a command, echo it like a prompt, and append output to a log file.
export PATH="$PATH:/usr/local/bin:$HOME/.docker/bin:/Applications/Docker.app/Contents/Resources/bin:/Applications/Docker Desktop.app/Contents/Resources/bin"
TASK4_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$TASK4_DIR/logs"
mkdir -p "$LOG_DIR"
run() {
  local log="$1"; shift
  printf '\n\033[1;32m%s$\033[0m %s\n' "$(whoami)@mac" "$*" | tee -a "$LOG_DIR/$log"
  eval "$@" 2>&1 | tee -a "$LOG_DIR/$log"
  return ${PIPESTATUS[0]}
}

# Clear the screen before a step and snapshot it afterwards (used when SNAP=1)
section() { [ "$SNAP" = 1 ] && clear; }
shot() { [ "$SNAP" = 1 ] && "$TASK4_DIR/scripts/snap.sh" "$1"; }
