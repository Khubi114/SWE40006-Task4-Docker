#!/bin/bash
# Task 4.2 - build the web image and run it locally with the port published to the host
# Usage: ./task4_2_build_run.sh <dockerhub-username>
source "$(dirname "$0")/common.sh"
USER_NAME="${1:?dockerhub username}"; IMG="$USER_NAME/swe40006-web"
cd "$TASK4_DIR/web-app"
L=task4_2_build.log; : > "$LOG_DIR/$L"
section
run $L cat Dockerfile
shot 4.2_01_dockerfile
section
run $L "docker build --no-cache --progress=plain -t $IMG:1.0 . 2>&1 | grep -E '^#[0-9]+ (\[|DONE|naming|exporting to)|Successfully|writing image|naming to'"
run $L docker images $IMG
shot 4.2_02_docker_build
L=task4_2_run_local.log; : > "$LOG_DIR/$L"
section
docker rm -f swe40006-local >/dev/null 2>&1
run $L "docker run -d --name swe40006-local -p 8080:5000 -e APP_ENV=local-macbook -e 'GREETING=Hello from Docker Desktop on my MacBook' $IMG:1.0"
sleep 4
run $L "docker ps --filter name=swe40006-local"
run $L "docker port swe40006-local"
run $L "curl -s http://localhost:8080/health"
run $L "curl -s http://localhost:8080/api/info | python3 -m json.tool"
run $L docker logs swe40006-local
shot 4.2_03_local_run
