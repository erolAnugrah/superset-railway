#!/bin/bash
set -e

export SUPERSET_SQLALCHEMY_DATABASE_URI

# Initialize Superset database
superset db upgrade

# Create admin user if it doesn't exist
superset fab create-admin \
  --username ${ADMIN_USERNAME:-admin} \
  --firstname Admin \
  --lastname User \
  --email ${ADMIN_EMAIL:-admin@example.com} \
  --password ${ADMIN_PASSWORD:-admin} || true

# Start Superset (skip examples to speed up startup)
superset run -h 0.0.0.0 -p ${PORT:-8088}
