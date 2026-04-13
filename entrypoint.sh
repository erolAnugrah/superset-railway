#!/bin/bash
set -e

# Install psycopg2-binary into the venv that Superset uses (/app/.venv).
# The venv cannot see system-installed packages, so we must install directly
# into it. The venv may still be initialising when this script starts, so we
# retry for up to ~30 seconds before giving up.
VENV_PIP="/app/.venv/bin/pip"
echo "Waiting for venv pip at ${VENV_PIP}..."
for i in $(seq 1 30); do
  if [ -x "$VENV_PIP" ]; then
    break
  fi
  sleep 1
done

if [ -x "$VENV_PIP" ]; then
  echo "Installing psycopg2-binary into venv..."
  "$VENV_PIP" install --quiet psycopg2-binary || echo "Warning: venv pip install failed; continuing anyway."
else
  echo "Warning: venv pip not found after 30 s; falling back to system pip."
  pip install --quiet psycopg2-binary || echo "Warning: system pip install failed; continuing anyway."
fi

# Resolve the database URI:
#   1. Use SUPERSET_SQLALCHEMY_DATABASE_URI if already set and non-empty.
#   2. Otherwise, construct it from Railway's individual Postgres credentials
#      (PGUSER, PGPASSWORD, PGDATABASE) using the public TCP proxy endpoint
#      yamabiko.proxy.rlwy.net:5432. The private DNS name
#      postgres.railway.internal may not resolve correctly, so the TCP proxy
#      is used instead. The individual PG* variables are available on the
#      Postgres service.
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

  SUPERSET_SQLALCHEMY_DATABASE_URI="postgresql://${PGUSER}:${PGPASSWORD}@yamabiko.proxy.rlwy.net:5432/${PGDATABASE}"
  echo "Constructed database URI using yamabiko.proxy.rlwy.net TCP proxy."
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
