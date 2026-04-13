#!/bin/bash
set -e

# Resolve the database URI:
#   1. Use SUPERSET_SQLALCHEMY_DATABASE_URI if already set and non-empty.
#   2. Otherwise, use the DATABASE variable that Railway provides directly
#      (reference variables like ${{ Postgres.PGHOST }} don't resolve in the
#      container at runtime, but DATABASE is a plain variable set to the full
#      Postgres connection string).
#   3. Hard-fail if neither option is available so Superset never silently
#      falls back to SQLite.
if [ -n "$SUPERSET_SQLALCHEMY_DATABASE_URI" ]; then
  echo "Using SUPERSET_SQLALCHEMY_DATABASE_URI for database connection."
elif [ -n "$DATABASE" ]; then
  echo "SUPERSET_SQLALCHEMY_DATABASE_URI is not set; using DATABASE variable."
  SUPERSET_SQLALCHEMY_DATABASE_URI="$DATABASE"
else
  echo "ERROR: Neither SUPERSET_SQLALCHEMY_DATABASE_URI nor DATABASE is set." \
       "Please set the DATABASE variable to the Postgres connection string in Railway." >&2
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
