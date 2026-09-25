#!/bin/bash
# Task 4.3 runner: compose network + env vars locally, then check the public Render URL.
cd "$(dirname "$0")"; source scripts/common.sh
printf '\e[8;48;120t'
export SNAP=1
scripts/task4_3_compose.sh "$(cat scripts/dockerhub_user.txt)"
echo "DONE $(date)" > logs/.compose_done
echo; echo "Task 4.3 evidence captured. Screenshot helper running - leave this window open until Claude says it's done."
cd screenshots
while true; do
  for req in .req_*; do
    [ -e "$req" ] || continue
    spec="${req#.req_}"; rm -f "$req"
    if [[ "$spec" == win_* ]]; then            # win_<windowid>_<name> -> capture one window only
      rest="${spec#win_}"; wid="${rest%%_*}"; name="${rest#*_}"
      screencapture -x -o -l "$wid" "$name.png" && echo "$(date +%T) saved $name.png"
    else
      screencapture -x "$spec.png" && echo "$(date +%T) saved $spec.png"
    fi
  done
  sleep 1
done
