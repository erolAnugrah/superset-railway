#!/bin/bash
set -e

echo "Using SQLite for Superset metadata store."

echo "Running database migrations..."
superset db upgrade

echo "Initializing Superset..."
superset init

echo "Creating admin user..."
superset fab create-admin \
  --username admin \
  --firstname Admin \
  --lastname User \
  --email admin@example.com \
  --password admin || echo "Admin user may already exist; continuing."

echo "Starting Superset..."
exec superset run \
  --host 0.0.0.0 \
  --port "${PORT:-8088}" \
  --with-threads \
  --debugger
