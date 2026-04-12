FROM apache/superset:latest

USER root
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

USER superset
ENTRYPOINT ["/app/entrypoint.sh"]
