#!/bin/bash
set -e

# Resolve the database URI:
#   1. Use SUPERSET_SQLALCHEMY_DATABASE_URI if already set and non-empty.
#   2. Otherwise, construct it from individual Postgres variables that
#      Railway's auto-provisioned Postgres service exposes: PGHOST, PGUSER,
#      PGPORT, PGPASSWORD, PGDATABASE.
#   3. Hard-fail if neither option is available so Superset never silently
#      falls back to SQLite.
if [ -n "$SUPERSET_SQLALCHEMY_DATABASE_URI" ]; then
  echo "Using SUPERSET_SQLALCHEMY_DATABASE_URI for database connection."
elif [ -n "$PGHOST" ] && [ -n "$PGUSER" ] && [ -n "$PGPORT" ] && [ -n "$PGPASSWORD" ] && [ -n "$PGDATABASE" ]; then
  echo "SUPERSET_SQLALCHEMY_DATABASE_URI is not set; constructing from PG* variables."
  SUPERSET_SQLALCHEMY_DATABASE_URI="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
  echo "Database URI constructed from PG* variables (password redacted): postgresql://${PGUSER}:***@${PGHOST}:${PGPORT}/${PGDATABASE}"
else
  echo "ERROR: SUPERSET_SQLALCHEMY_DATABASE_URI is not set and one or more of" \
       "PGHOST, PGUSER, PGPORT, PGPASSWORD, PGDATABASE are missing." \
       "Please link a Postgres service or set SUPERSET_SQLALCHEMY_DATABASE_URI in Railway." >&2
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
