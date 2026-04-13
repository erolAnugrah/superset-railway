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

# Suppress SQLAlchemy modification-tracking overhead (not used by Superset).
SQLALCHEMY_TRACK_MODIFICATIONS = False

# SQLite requires check_same_thread=False to work correctly with Flask's
# threaded request model.  PostgreSQL does not accept this connect_arg, so
# the extra option is only applied when falling back to a SQLite database.
# Use _uri (may be None when no DB env vars are set) to avoid a NameError
# on SQLALCHEMY_DATABASE_URI, which is only defined when _uri is truthy.
_is_sqlite = _uri is None or _uri.startswith("sqlite")
if _is_sqlite:
    SQLALCHEMY_ENGINE_OPTIONS = {
        "connect_args": {"check_same_thread": False},
        "pool_pre_ping": True,
        "pool_recycle": 3600,
    }
else:
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,
        "pool_recycle": 3600,
    }
