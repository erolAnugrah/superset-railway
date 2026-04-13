FROM apache/superset:latest

USER root
RUN /app/.venv/bin/pip install "psycopg[binary]"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY superset_config.py /app/superset_config.py

USER superset

ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

ENTRYPOINT ["/entrypoint.sh"]
