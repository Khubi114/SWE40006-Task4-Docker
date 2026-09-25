#!/bin/bash
# Task 4.4 - build and run the non-web processor, showing lifecycle and persistence
source "$(dirname "$0")/common.sh"
export DOCKERHUB_USER="${1:-khubi114}"
cd "$TASK4_DIR/data-processor"
L=task4_4_lifecycle.log; : > "$LOG_DIR/$L"
section
docker rm -f proc-run1 >/dev/null 2>&1; docker volume rm swe40006-processor-state >/dev/null 2>&1; rm -f sample-data/output/*
run $L cat docker-compose.yml
run $L "docker compose build 2>&1 | tail -4"
run $L ls sample-data/input
shot 4.4_01_compose_build
section
echo "---- RUN 1: fresh volume, all files are new ----" | tee -a "$LOG_DIR/$L"
run $L docker compose run --name proc-run1 processor
run $L "docker inspect proc-run1 --format 'State={{.State.Status}} ExitCode={{.State.ExitCode}} Started={{.State.StartedAt}} Finished={{.State.FinishedAt}}'"
run $L "ls -l sample-data/output"
shot 4.4_02_run1_exit0
section
run $L "docker ps -a --filter name=proc-run1"
run $L "docker logs proc-run1 | head -5"
run $L "docker volume inspect swe40006-processor-state --format 'Volume {{.Name}} -> {{.Mountpoint}}'"
run $L "cat sample-data/output/*.json"
shot 4.4_03_logs_volume_output
section
echo "---- RUN 2: new container, same volume -> files skipped ----" | tee -a "$LOG_DIR/$L"
run $L "docker compose run --rm processor 2>/dev/null"
echo "---- RUN 3: history read from the named volume ----" | tee -a "$LOG_DIR/$L"
run $L "docker compose run --rm processor --history 2>/dev/null"
run $L docker rm proc-run1
run $L "docker ps -a --filter ancestor=$DOCKERHUB_USER/swe40006-processor:1.0"
shot 4.4_04_persistence_rerun
