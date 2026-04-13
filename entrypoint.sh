#!/bin/bash
set -e

# --- Postgres URI construction (disabled) ---
# Superset is currently configured to use SQLite (see superset_config.py).
# Re-enable this block once a working Postgres driver is available in the venv.
#
# if [ -n "$SUPERSET_SQLALCHEMY_DATABASE_URI" ]; then
#   echo "Using SUPERSET_SQLALCHEMY_DATABASE_URI for database connection."
# else
#   echo "SUPERSET_SQLALCHEMY_DATABASE_URI is not set; constructing from PG* variables."
#
#   if [ -z "$PGUSER" ]; then
#     echo "ERROR: PGUSER is not set. Cannot construct Postgres connection string." >&2
#     exit 1
#   fi
#   if [ -z "$PGPASSWORD" ]; then
#     echo "ERROR: PGPASSWORD is not set. Cannot construct Postgres connection string." >&2
#     exit 1
#   fi
#   if [ -z "$PGDATABASE" ]; then
#     echo "ERROR: PGDATABASE is not set. Cannot construct Postgres connection string." >&2
#     exit 1
#   fi
#
#   SUPERSET_SQLALCHEMY_DATABASE_URI="postgresql+psycopg://${PGUSER}:${PGPASSWORD}@yamabiko.proxy.rlwy.net:5432/${PGDATABASE}"
#   echo "Constructed database URI using yamabiko.proxy.rlwy.net TCP proxy."
# fi
#
# export SUPERSET_SQLALCHEMY_DATABASE_URI

echo "Using SQLite for Superset metadata store (sqlite:////tmp/superset.db)."

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
  --debugger
