#!/bin/bash
# Task 4.1 - verify Docker install and run hello-world
source "$(dirname "$0")/common.sh"
L=task4_1_hello_world.log; : > "$LOG_DIR/$L"
section
run $L docker --version
run $L docker compose version
run $L "docker info --format 'Server {{.ServerVersion}} | OS {{.OperatingSystem}} | Arch {{.Architecture}} | CPUs {{.NCPU}} | Mem {{.MemTotal}}'"
run $L "docker info 2>/dev/null | grep -E 'Username|Registry|Context|Storage Driver'"
shot 4.1_02_docker_version_info
section
docker rm -f hello-test >/dev/null 2>&1; docker rmi hello-world >/dev/null 2>&1
run $L docker run --name hello-test hello-world
run $L "docker ps -a --filter name=hello-test"
run $L docker images hello-world
shot 4.1_03_hello_world_run
