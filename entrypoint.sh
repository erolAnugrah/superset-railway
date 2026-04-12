#!/bin/bash
set -e

# Initialize Superset database
superset db upgrade

# Create admin user if it doesn't exist
superset fab create-admin \
  --username ${ADMIN_USERNAME:-admin} \
  --firstname Admin \
  --lastname User \
  --email ${ADMIN_EMAIL:-admin@example.com} \
  --password ${ADMIN_PASSWORD:-admin} || true

# Load examples
superset load_examples || true

# Start Superset
superset run -h 0.0.0.0 -p ${PORT:-8088}
