#!/bin/bash
# Task 4.2 - push to Docker Hub (multi-arch so the same tag runs on amd64 hosts like Render / Play with Docker)
source "$(dirname "$0")/common.sh"
USER_NAME="${1:?dockerhub username}"; IMG="$USER_NAME/swe40006-web"
cd "$TASK4_DIR/web-app"
L=task4_2_push.log; : > "$LOG_DIR/$L"
section
run $L "docker info 2>/dev/null | grep Username"
run $L "docker buildx create --name swe40006-builder --use >/dev/null 2>&1 || docker buildx use swe40006-builder"
run $L "docker buildx build --platform linux/amd64,linux/arm64 -t $IMG:1.0 -t $IMG:latest --push . 2>&1 | grep -E 'pushing|DONE [0-9.]+s$|manifest list|naming' | tail -25"
run $L "docker buildx imagetools inspect $IMG:1.0 | grep -E 'Name|Platform: *linux'"
shot 4.2_04_push_dockerhub
