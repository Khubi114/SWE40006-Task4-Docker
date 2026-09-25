"""SWE40006 Task 4 - Container Info web app (Tasks 4.2 and 4.3).

A small Flask app that reports where it is running. All behaviour that
changes between environments (port, environment name, greeting, version)
comes from environment variables so the same image runs unchanged on a
laptop, on Play with Docker and on Render.
"""
import os
import platform
import socket
from datetime import datetime, timezone

from flask import Flask, jsonify, render_template

app = Flask(__name__)

STARTED_AT = datetime.now(timezone.utc)
REQUEST_COUNT = 0


def settings():
    return {
        "app_name": os.getenv("APP_NAME", "SWE40006 Container Info"),
        "app_env": os.getenv("APP_ENV", "development"),
        "app_version": os.getenv("APP_VERSION", "1.0.0"),
        "greeting": os.getenv("GREETING", "Hello from a Docker container!"),
        "owner": os.getenv("APP_OWNER", "Khubi Shah"),
        "port": int(os.getenv("PORT", "5000")),
    }


def runtime_info():
    uptime = datetime.now(timezone.utc) - STARTED_AT
    return {
        "hostname": socket.gethostname(),
        "container_ip": _container_ip(),
        "python": platform.python_version(),
        "platform": f"{platform.system()} {platform.machine()}",
        "started_at": STARTED_AT.strftime("%Y-%m-%d %H:%M:%S UTC"),
        "uptime_seconds": int(uptime.total_seconds()),
        "requests_served": REQUEST_COUNT,
    }


def _container_ip():
    try:
        return socket.gethostbyname(socket.gethostname())
    except OSError:
        return "unknown"


@app.before_request
def count_request():
    global REQUEST_COUNT
    REQUEST_COUNT += 1


@app.route("/")
def index():
    return render_template("index.html", cfg=settings(), rt=runtime_info())


@app.route("/health")
def health():
    return jsonify(status="ok", time=datetime.now(timezone.utc).isoformat())


@app.route("/api/info")
def info():
    cfg = settings()
    return jsonify(config=cfg, runtime=runtime_info())


if __name__ == "__main__":
    # Local dev only. In the container gunicorn serves the app (see Dockerfile).
    app.run(host="0.0.0.0", port=settings()["port"])
