#!/bin/bash
# One-click runner for Tasks 4.1, 4.2 (local build/run + push) and 4.4.
# Afterwards it stays open as a screenshot helper so browser / Docker Desktop
# evidence can be captured on cue. Close the window when Task 4 is finished.
cd "$(dirname "$0")"; source scripts/common.sh
printf '\e[8;48;120t'          # resize Terminal to 130x46 so screenshots are readable
U="$(cat scripts/dockerhub_user.txt)"
export SNAP=1
scripts/task4_1_verify.sh
scripts/task4_2_build_run.sh "$U"
scripts/task4_2_push.sh "$U"
scripts/task4_4_run.sh "$U"
echo "DONE $(date)" > logs/.run_done

clear
echo "Task 4 scripts finished. Screenshot helper is now running - leave this window open."
cd screenshots
while true; do
  for req in .req_*; do
    [ -e "$req" ] || continue
    name="${req#.req_}"; rm -f "$req"
    screencapture -x "$name.png" && echo "$(date +%T) saved $name.png"
  done
  sleep 1
done
