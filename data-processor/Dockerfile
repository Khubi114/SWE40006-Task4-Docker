# SWE40006 Task 4.4 - non-web batch container (expense report processor)
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    INPUT_DIR=/data/input \
    OUTPUT_DIR=/data/output \
    STATE_DIR=/data/state \
    CURRENCY=AUD

WORKDIR /app
COPY processor.py .

# Non-root user that owns the data folders
RUN useradd --create-home --uid 1000 worker \
 && mkdir -p /data/input /data/output /data/state \
 && chown -R worker:worker /data
USER worker

# /data/state is declared as a volume so run history survives container removal
VOLUME ["/data/state"]

# No ports: this is a run-to-completion job, not a server
ENTRYPOINT ["python", "processor.py"]
