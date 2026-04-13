#!/bin/bash
set -e

# Resolve the database URI: prefer SUPERSET_SQLALCHEMY_DATABASE_URI, fall back
# to DATABASE (Railway's auto-provisioned Postgres URL), and hard-fail if
# neither is available so Superset never silently falls back to SQLite.
if [ -n "$SUPERSET_SQLALCHEMY_DATABASE_URI" ]; then
  echo "Using SUPERSET_SQLALCHEMY_DATABASE_URI for database connection."
elif [ -n "$DATABASE" ]; then
  echo "SUPERSET_SQLALCHEMY_DATABASE_URI is empty; falling back to DATABASE variable."
  SUPERSET_SQLALCHEMY_DATABASE_URI="$DATABASE"
else
  echo "ERROR: Neither SUPERSET_SQLALCHEMY_DATABASE_URI nor DATABASE is set." \
       "Please configure a Postgres connection string in Railway." >&2
  exit 1
fi

export SUPERSET_SQLALCHEMY_DATABASE_URI

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
