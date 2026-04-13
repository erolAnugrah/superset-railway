#!/bin/bash
set -e

# Ensure SUPERSET_SQLALCHEMY_DATABASE_URI is set (provided by Railway)
if [ -z "$SUPERSET_SQLALCHEMY_DATABASE_URI" ]; then
  echo "ERROR: SUPERSET_SQLALCHEMY_DATABASE_URI is not set. Please configure it in Railway." >&2
  exit 1
fi

export SUPERSET_SQLALCHEMY_DATABASE_URI="$SUPERSET_SQLALCHEMY_DATABASE_URI"

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

echo "Starting Superset..."
exec superset run \
  --host 0.0.0.0 \
  --port "${PORT:-8088}" \
  --with-threads \
  --reload \
  --debugger
