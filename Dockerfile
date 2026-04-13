FROM apache/superset:latest

USER root

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER superset

ENTRYPOINT ["/entrypoint.sh"]
