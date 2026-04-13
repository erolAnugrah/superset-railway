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
            f"postgresql://{_pguser}:{_pgpassword}"
            f"@yamabiko.proxy.rlwy.net:5432/{_pgdatabase}"
        )

if _uri:
    SQLALCHEMY_DATABASE_URI = _uri
