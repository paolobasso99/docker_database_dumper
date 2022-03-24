FROM alpine:3

RUN apk update
RUN apk add --no-cache --update \
    apk-cron \
    mysql-client \
    postgresql-client

ENV PGID="**None**" \
    PUID="**None**" \
    DUMPER_TYPE="**None**" \
    DUMPER_DATABASE="**None**" \
    DUMPER_HOST="**None**" \
    DUMPER_PORT="**None**" \
    DUMPER_USER="**None**" \
    DUMPER_PASSWORD="**None**" \
    DUMPER_KEEP=7 \
    DUMPER_SCHEDULE="0 3 * * *" \
    DUMPER_HEALTHCHECKS_URL="**None**" \
    DUMPER_POSTGRES_CLUSTER="false"

COPY dump.sh /dump.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /dump.sh /entrypoint.sh

VOLUME /dumps

CMD [ "/entrypoint.sh" ]
