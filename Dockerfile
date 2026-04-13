FROM apache/superset:latest

USER root

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY superset_config.py /app/superset_config.py

RUN /app/.venv/bin/pip install psycopg2-binary

USER superset

ENV SUPERSET_CONFIG_PATH=/app/superset_config.py

ENTRYPOINT ["/entrypoint.sh"]
