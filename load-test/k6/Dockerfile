FROM grafana/k6:latest

WORKDIR /scripts

COPY *.js /scripts/
COPY entrypoint.sh /entrypoint.sh

USER root
RUN chmod +x /entrypoint.sh
USER k6

ENV SCENARIO=shoply-order-payment.js
ENV BASE_URL=http://host.docker.internal:4000
ENV VUS=100
ENV DURATION=5m
ENV SLEEP_SECONDS=1

ENTRYPOINT ["/entrypoint.sh"]
