#!/bin/bash
set -e

# Generate superset_config.py from environment variables
cat > /app/superset_config.py << 'EOF'
import os

SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'default-secret-key')
SQLALCHEMY_DATABASE_URI = os.environ.get('SUPERSET_SQLALCHEMY_DATABASE_URI', 'sqlite:////app/superset.db')
EOF

export SUPERSET_CONFIG_PATH=/app/superset_config.py

# Run superset
exec superset run -p 8088 -h 0.0.0.0
