# SWE40006 Task 4 – Docker containerisation (HD level, 4.1 → 4.4)

Khubi Shah · 105933114 · SWE40006 Software Deployment and Evolution · Semester 2, 2026

| Level | What it shows | Where |
|---|---|---|
| 4.1 Pass | Docker Desktop 4.92 on macOS (Apple silicon), Docker Hub account `khubi114`, `hello-world` run | `scripts/task4_1_verify.sh`, `logs/task4_1_hello_world.log` |
| 4.2 Credit | Flask app, custom Dockerfile, local run on port 8080, multi-arch push to Docker Hub, pull-and-run on a second host (GitHub Actions runner) | `web-app/`, `scripts/task4_2_*.sh`, `.github/workflows/secondary-host-verify.yml` |
| 4.3 Distinction | Same image deployed on Render with env vars, public HTTPS URL | `web-app/docker-compose.yml`, `web-app/.env.example` |
| 4.4 High Distinction | Non-web CLI expense processor, bind mounts + named volume, run-to-completion lifecycle and logs | `data-processor/`, `scripts/task4_4_run.sh` |

**Docker Hub:** https://hub.docker.com/r/khubi114/swe40006-web  
**Live URL (Render):** RENDER_URL

## Layout

```
web-app/            Flask app (app.py, templates/), Dockerfile, compose file, .env.example
data-processor/     processor.py, Dockerfile, compose file, sample-data/input/*.csv
scripts/            the exact scripts run on the Mac (output tee'd to logs/)
logs/               raw console output of every build / run / push
.github/workflows/  secondary Docker host verification (pull from Docker Hub and run)
Run_Task4.command   macOS double-click runner for 4.1, 4.2 and 4.4
```

## Reproduce

```bash
# 4.1
docker run hello-world

# 4.2 – build and run locally
cd web-app
docker build -t khubi114/swe40006-web:1.0 .
docker run -d --name swe40006-local -p 8080:5000 -e APP_ENV=local khubi114/swe40006-web:1.0
curl http://localhost:8080/health

# 4.2 – push (amd64 + arm64 so it also runs on x86 hosts)
docker buildx build --platform linux/amd64,linux/arm64 -t khubi114/swe40006-web:1.0 --push .

# 4.3 – compose with a user-defined bridge network and env file
cp .env.example .env && DOCKERHUB_USER=khubi114 docker compose up -d

# 4.4 – batch job with bind mounts and a named volume
cd ../data-processor
docker compose run --rm processor              # processes the CSVs, writes sample-data/output/
docker compose run --rm processor              # same volume -> already-processed files are skipped
docker compose run --rm processor --history    # run history read from the swe40006-processor-state volume
```

## Environment variables (web app)

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | 5000 | Port gunicorn binds to (Render injects its own) |
| `APP_ENV` | production | Shown on the page, identifies the host |
| `APP_VERSION` | 1.0.0 | Release label |
| `GREETING` | Hello from a Docker container! | Banner text |
| `APP_OWNER` | Khubi Shah | Footer |

No secrets are stored in this repository. `.env` is git-ignored; only `.env.example` is committed.
