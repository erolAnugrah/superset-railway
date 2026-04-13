import os

# Use SQLite as the metadata store so Superset can start without any
# external Postgres driver installed in the venv.  Once the UI is
# accessible, the Postgres connection can be configured separately.
SQLALCHEMY_DATABASE_URI = "sqlite:////tmp/superset.db"

# --- Postgres URI construction (disabled) ---
# Kept here for reference; re-enable once psycopg2/psycopg3 is importable.
#
# _uri = os.environ.get("SUPERSET_SQLALCHEMY_DATABASE_URI")
#
# if not _uri:
#     _pguser     = os.environ.get("PGUSER", "")
#     _pgpassword = os.environ.get("PGPASSWORD", "")
#     _pgdatabase = os.environ.get("PGDATABASE", "")
#
#     if _pguser and _pgpassword and _pgdatabase:
#         _uri = (
#             f"postgresql+psycopg://{_pguser}:{_pgpassword}"
#             f"@yamabiko.proxy.rlwy.net:5432/{_pgdatabase}"
#         )
#
# if _uri:
#     SQLALCHEMY_DATABASE_URI = _uri
