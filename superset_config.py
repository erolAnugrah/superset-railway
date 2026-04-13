import os

# Resolve the SQLAlchemy database URI for Superset's metadata store.
#
# Priority:
#   1. SUPERSET_SQLALCHEMY_DATABASE_URI — use as-is if set.
#   2. Construct from Railway's individual Postgres credentials
#      (PGUSER, PGPASSWORD, PGDATABASE) via the public TCP proxy
#      yamabiko.proxy.rlwy.net:5432.
#
# This file is evaluated at Python import time, so the URI is available
# before any Superset module reads the configuration — avoiding the
# silent SQLite fallback that occurs when the value is only exported
# by the entrypoint shell script after Python has already started.

_uri = os.environ.get("SUPERSET_SQLALCHEMY_DATABASE_URI")

if not _uri:
    _pguser = os.environ.get("PGUSER", "")
    _pgpassword = os.environ.get("PGPASSWORD", "")
    _pgdatabase = os.environ.get("PGDATABASE", "")

    if _pguser and _pgpassword and _pgdatabase:
        _uri = (
            f"postgresql+psycopg://{_pguser}:{_pgpassword}"
            f"@yamabiko.proxy.rlwy.net:5432/{_pgdatabase}"
        )

if _uri:
    SQLALCHEMY_DATABASE_URI = _uri

# ---------------------------------------------------------
# Production settings replicated from alchemist-prod
# ---------------------------------------------------------
SECRET_KEY = 'TmV3U2VjcmV0S2V5Rm9yU3VwZXJzZXRQbGVhc2VHZW5lcmF0ZUEgU3Ryb25nUmFuZG9tS2V5'

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "EMBEDDED_SUPERSET": True,
}

WTF_CSRF_ENABLED = False
TALISMAN_ENABLED = False
CONTENT_SECURITY_POLICY_WARNING = False

GUEST_ROLE_NAME = "Gamma"  
GUEST_TOKEN_JWT_SECRET = "s02Z2TVgsh0aBqob0bpXxTUr5UF3X80dXUXmSMVNRSuyrowit2Ivv-VHNRbNxDl1waP28Ecm7PygWLNHayY_JQ"
GUEST_TOKEN_JWT_ALGO = "HS256"
GUEST_TOKEN_HEADER_NAME = "X-GuestToken"
GUEST_TOKEN_JWT_EXP_SECONDS = 3600  # 1 Hour

ENABLE_CORS = True
ALLOWED_EMBEDDED_DOMAINS = [
    "https://superset.alchemistfragrance.com",
    "https://dashboard.alchemistfragrance.com",
    "https://demo-be-alchemist.kayazta.id"
]

HTTP_HEADERS = {"X-Frame-Options": "ALLOWALL"}  # SAMEORIGIN

CORS_OPTIONS = {
    "supports_credentials": True,
    "allow_headers": ["*"],
    "resources": ["*"],
    "origins": [
        "https://dashboard.alchemistfragrance.com",
        "https://demo-be-alchemist.kayazta.id"
    ],
}

# ---------------------------------------------------------
# Redis Cache & Celery Worker Configuration
# ---------------------------------------------------------
from celery.schedules import crontab

# Railway usually provides REDIS_URL for its Redis plugins
_redis_url = os.environ.get("REDIS_URL", "redis://redis:6379/0")

RATELIMIT_STORAGE_URI = _redis_url

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_cache_",
    "CACHE_REDIS_URL": _redis_url,
}
DATA_CACHE_CONFIG = CACHE_CONFIG

class CeleryConfig:
    broker_url = _redis_url
    imports = ("superset.sql_lab", "superset.tasks.scheduler")
    result_backend = _redis_url
    worker_prefetch_multiplier = 1
    task_acks_late = False
    beat_schedule = {
        "reports.scheduler": {
            "task": "superset.tasks.scheduler.scheduler",
            "schedule": crontab(minute="*", hour="*"),
        },
        "reports.prune_log": {
            "task": "superset.tasks.scheduler.prune_log",
            "schedule": crontab(minute=10, hour=0),
        },
    }

CELERY_CONFIG = CeleryConfig
