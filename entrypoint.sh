#!/bin/bash
set -e

# Resolve the database URI:
#   1. Use SUPERSET_SQLALCHEMY_DATABASE_URI if already set and non-empty.
#   2. Otherwise, construct it from Railway's individual Postgres credentials
#      (PGUSER, PGPASSWORD, PGDATABASE) using the private DNS name
#      postgres.railway.internal. Reference variables like
#      ${{postgres.DATABASE_URL}} don't resolve in the container at runtime,
#      but the individual PG* variables are available on the Postgres service.
#   3. Hard-fail if neither option is available so Superset never silently
#      falls back to SQLite.
if [ -n "$SUPERSET_SQLALCHEMY_DATABASE_URI" ]; then
  echo "Using SUPERSET_SQLALCHEMY_DATABASE_URI for database connection."
else
  echo "SUPERSET_SQLALCHEMY_DATABASE_URI is not set; constructing from PG* variables."

  if [ -z "$PGUSER" ]; then
    echo "ERROR: PGUSER is not set. Cannot construct Postgres connection string." >&2
    exit 1
  fi
  if [ -z "$PGPASSWORD" ]; then
    echo "ERROR: PGPASSWORD is not set. Cannot construct Postgres connection string." >&2
    exit 1
  fi
  if [ -z "$PGDATABASE" ]; then
    echo "ERROR: PGDATABASE is not set. Cannot construct Postgres connection string." >&2
    exit 1
  fi

  SUPERSET_SQLALCHEMY_DATABASE_URI="postgresql://${PGUSER}:${PGPASSWORD}@postgres.railway.internal:5432/${PGDATABASE}"
  echo "Constructed database URI using postgres.railway.internal."
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
exec env SUPERSET_SQLALCHEMY_DATABASE_URI="$SUPERSET_SQLALCHEMY_DATABASE_URI" \
  superset run \
  --host 0.0.0.0 \
  --port "${PORT:-8088}" \
  --with-threads \
  --debugger
