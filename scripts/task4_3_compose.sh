#!/bin/bash
# Task 4.3 - container networking + environment variables with Docker Compose,
# then check the public Render deployment of the same image.
source "$(dirname "$0")/common.sh"
export DOCKERHUB_USER="${1:-khubi114}"
PUBLIC_URL="$(cat "$TASK4_DIR/scripts/public_url.txt")"
cd "$TASK4_DIR/web-app"
L=task4_3_compose_network.log; : > "$LOG_DIR/$L"
section
docker rm -f swe40006-local >/dev/null 2>&1   # free port 8080 from the 4.2 run
[ -f .env ] || cp .env.example .env
run $L cat .env
run $L cat docker-compose.yml
run $L "docker compose up -d 2>&1"
sleep 5
run $L docker compose ps
shot 4.3_01_compose_up
section
run $L "docker network ls --filter name=swe40006"
run $L "docker network inspect web-app_swe40006-net --format 'Network={{.Name}} Driver={{.Driver}} Subnet={{range .IPAM.Config}}{{.Subnet}}{{end}} Containers={{range .Containers}}{{.Name}}@{{.IPv4Address}} {{end}}'"
run $L "docker exec swe40006-web env | grep -E '^(APP_|GREETING|PORT)' | sort"
run $L "curl -s http://localhost:8080/api/info | python3 -m json.tool"
shot 4.3_02_network_env
section
run $L "curl -sS -o /dev/null -w 'HTTP %{http_code}  %{time_total}s  %{remote_ip}\n' $PUBLIC_URL/"
run $L "curl -sS $PUBLIC_URL/health"
run $L "curl -sS $PUBLIC_URL/api/info | python3 -m json.tool"
run $L "curl -sSI $PUBLIC_URL/ | grep -iE '^(HTTP|content-type|server)'"
shot 4.3_03_public_https
