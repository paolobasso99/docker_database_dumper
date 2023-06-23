FROM alpine:3 AS base

RUN apk update
RUN apk upgrade
RUN apk add --no-cache --update apk-cron

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

FROM base as postgres-base
ENV DUMPER_TYPE="postgres"

FROM postgres-base AS postgres-15
RUN apk add --no-cache --update postgresql15-client

FROM postgres-base AS postgres-14
RUN apk add --no-cache --update postgresql14-client

FROM postgres-base AS postgres-13
RUN apk add --no-cache --update postgresql13-client

FROM postgres-base AS postgres-12
RUN apk add --no-cache --update postgresql12-client

FROM base as mariadb
ENV DUMPER_TYPE="mysql"
RUN apk add --no-cache --update mariadb-client

FROM base as mysql
ENV DUMPER_TYPE="mysql"
RUN apk add --no-cache --update mysql-client