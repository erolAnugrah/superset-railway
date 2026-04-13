#!/bin/bash
set -e

echo "Using SQLite for Superset metadata store."

ROLE="${SUPERSET_ROLE:-app}"

if [ "$ROLE" = "app" ]; then
  echo "Running database migrations..."
  superset db upgrade

  echo "Creating admin user..."
  superset fab create-admin \
    --username "${ADMIN_USERNAME:-admin}" \
    --firstname "${ADMIN_FIRST_NAME:-Admin}" \
    --lastname "${ADMIN_LAST_NAME:-User}" \
    --email "${ADMIN_EMAIL:-admin@superset.com}" \
    --password "${ADMIN_PASSWORD:-admin}" \
    || true  # Don't fail if the user already exists

  echo "Initializing Superset..."
  superset init

  echo "Starting Superset Web Server (Gunicorn)..."
  exec gunicorn \
    --bind "0.0.0.0:${PORT:-8088}" \
    --access-logfile - \
    --error-logfile - \
    --workers 1 \
    --worker-class gthread \
    --threads 20 \
    --timeout 60 \
    --limit-request-line 0 \
    --limit-request-field_size 0 \
    "superset.app:create_app()"
    
elif [ "$ROLE" = "worker" ]; then
  echo "Starting Superset Celery Worker..."
  exec celery \
    --app=superset.tasks.celery_app:app \
    worker \
    -O fair \
    -l INFO \
    --concurrency=2

elif [ "$ROLE" = "beat" ]; then
  echo "Starting Superset Celery Beat..."
  exec celery \
    --app=superset.tasks.celery_app:app \
    beat \
    --pidfile /tmp/celerybeat.pid \
    -l INFO
    
else
  echo "Unknown SUPERSET_ROLE: $ROLE"
  exit 1
fi
