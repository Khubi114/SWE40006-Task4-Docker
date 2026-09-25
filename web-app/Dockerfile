# SWE40006 Task 4.2 / 4.3 - Flask web app image
FROM python:3.12-slim

# Python runtime settings: no .pyc files, unbuffered logs so `docker logs` is live
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000 \
    APP_ENV=production

WORKDIR /app

# Install dependencies first so this layer is cached between code changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY app.py .
COPY templates/ templates/

# Run as a non-root user
RUN useradd --create-home appuser
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:'+os.getenv('PORT','5000')+'/health')" || exit 1

# Shell form so $PORT is expanded at runtime (Render injects its own PORT)
CMD gunicorn --bind 0.0.0.0:${PORT} --workers 2 --access-logfile - app:app
