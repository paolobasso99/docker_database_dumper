#!/bin/sh

function start_healthcheck {
    if [ "${DUMPER_HEALTHCHECKS_URL}" != "**None**" ] && [ -z "${DUMPER_HEALTHCHECKS_URL}" ]; then
        echo "Sending start health check to ${DUMPER_HEALTHCHECKS_URL}"
        wget --quiet --spider --timeout=2 --tries=10 ${DUMPER_HEALTHCHECKS_URL}/start

        local CODE=$?
        if [ $CODE -ne 0 ]; then
            echo "The health check failed (exit code $CODE), check for errors in the log."
            exit 1
        fi
    fi
}

function stop_healthcheck {
    if [ "${DUMPER_HEALTHCHECKS_URL}" != "**None**" ] && [ -z "${DUMPER_HEALTHCHECKS_URL}" ]; then
        echo "Sending stop health check to ${DUMPER_HEALTHCHECKS_URL}"
        wget --quiet --spider --timeout=2 --tries=10 ${DUMPER_HEALTHCHECKS_URL}
    fi
}

function fail_healthcheck {
    if [ "${DUMPER_HEALTHCHECKS_URL}" != "**None**" ] && [ -z "${DUMPER_HEALTHCHECKS_URL}" ]; then
        echo "Sending fail health check to ${DUMPER_HEALTHCHECKS_URL}"
        wget --quiet --spider --timeout=2 --tries=10 ${DUMPER_HEALTHCHECKS_URL}/fail
    fi
}

function check_environment_variables {
    local ENV_CORRECTLY_SET=0
    echo "Checking if required environment variables are set..."

    # Check variables
    if [ "${PUID}" = "**None**" ] || [ -z "${PUID}" ]; then
        echo "You need to set the PUID environment variable."
        ENV_CORRECTLY_SET=1
    fi
    if [ "${PGID}" = "**None**" ] || [ -z "${PGID}" ]; then
        echo "You need to set the PGID environment variable."
        ENV_CORRECTLY_SET=1
    fi
    if [ "${DUMPER_TYPE}" != "mysql" ] && [ "${DUMPER_TYPE}" != "postgres" ]; then
        echo "You need to set the DUMPER_TYPE environment variable to 'mysql' or 'postgres'."
        exit 1
    fi
    if [ "${DUMPER_DATABASE}" = "**None**" ] || [ -z "${DUMPER_DATABASE}" ]; then
        echo "You need to set the DUMPER_DATABASE environment variable."
        ENV_CORRECTLY_SET=1
    fi
    if [ "${DUMPER_HOST}" = "**None**" ] || [ -z "${DUMPER_HOST}" ]; then
        echo "You need to set the DUMPER_HOST environment variable."
        ENV_CORRECTLY_SET=1
    fi
    if [ -z "${DUMPER_PORT}" ]; then
        echo "You need to set the DUMPER_PORT environment variable."
        ENV_CORRECTLY_SET=1
    fi
    if [ -z "${DUMPER_KEEP}" ]; then
        echo "You need to set the DUMPER_KEEP environment variable."
        ENV_CORRECTLY_SET=1
    fi
    if [ "${DUMPER_USER}" = "**None**" ] || [ -z "${DUMPER_USER}" ]; then
        echo "You need to set the DUMPER_USER environment variable."
        ENV_CORRECTLY_SET=1
    fi
    if [ "${DUMPER_PASSWORD}" = "**None**" ] || [ -z "${DUMPER_PASSWORD}" ]; then
        echo "You need to set the DUMPER_PASSWORD environment variable."
        ENV_CORRECTLY_SET=1
    fi
    if [ "${DUMPER_POSTGRES_CLUSTER}" != "false" ] && [ "${DUMPER_POSTGRES_CLUSTER}" != "true" ]; then
        echo "You need to set the DUMPER_POSTGRES_CLUSTER environment variable to 'false' or 'true'."
        exit 1
    fi

    # Fail healthcheck and exit if env is not correctly set
    if [ "${ENV_CORRECTLY_SET}" -ne 0 ]; then
        fail_healthcheck
        exit 1
    fi
}

function clean_old_dumps {
    echo "Cleaning older dumps for ${DUMPER_DATABASE} database from ${DUMPER_HOST}..."

    local NUMBER_OF_DUMPS=$(find /dumps -maxdepth 1 -type f -name "${DUMPER_DATABASE}-*" | wc -l)
    if [ $NUMBER_OF_DUMPS -gt $DUMPER_KEEP ]; then
        # [How do I delete all but 10 newest files in Linux? - superuser.com](https://superuser.com/a/708232)
        # [How to only get file name with Linux 'find'? - stackoverflow.com](https://stackoverflow.com/a/5458777)
        find /dumps -maxdepth 1 -type f -name "${DUMPER_DATABASE}-*" -exec readlink -f '{}' ';' | sort | head -n -"${DUMPER_KEEP}" | xargs rm

        local CODE=$?
        if [ $CODE -ne 0 ]; then
            echo "The cleaning of older dumps failed (exit code $CODE), check for errors in the log."
            fail_healthcheck
            exit 1
        fi
    else
        echo "No dump deleted because there are only $NUMBER_OF_DUMPS dumps and DUMPER_KEEP=$DUMPER_KEEP."
    fi
}

function create_dump {
    # Initialize filename
    local DUMP_FILE="/dumps/${DUMPER_DATABASE}-$(date +%Y-%m-%d-%H-%M-%S).sql"

    # Create dump
    if [ "${DUMPER_TYPE}" = "mysql" ]; then
        echo "Creating dump of ${DUMPER_DATABASE} database from ${DUMPER_HOST}..."
        mysqldump -h "${DUMPER_HOST}" --port="${DUMPER_PORT}" "${DUMPER_DATABASE}" >"${DUMP_FILE}"
    fi
    if [ "${DUMPER_TYPE}" = "postgres" ]; then
        if [ "${POSTGRES_CLUSTER}" = "true" ]; then
            echo "Creating cluster dump of ${POSTGRES_DB} database from ${POSTGRES_HOST}..."
            pg_dumpall -h "${DUMPER_HOST}" -p "${DUMPER_PORT}" -U "${DUMPER_USER}" --database="${DUMPER_DATABASE}" >"${DUMP_FILE}"
        else
            echo "Creating dump of ${POSTGRES_DB} database from ${POSTGRES_HOST}..."
            pg_dump -h "${DUMPER_HOST}" -p "${DUMPER_PORT}" -U "${DUMPER_USER}" --dbname="${DUMPER_DATABASE}" >"${DUMP_FILE}"
        fi
    fi

    # Check if the dump file was correctly created
    if [ ! -s "$DUMP_FILE" ]; then
        echo "The dump failed, check for errors in the log."
        fail_healthcheck
        rm "$DUMP_FILE"
        exit 1
    fi

    # Gzip dump
    echo "Compress created dump..."
    gzip "${DUMP_FILE}"
    local CODE=$?
    if [ $CODE -ne 0 ]; then
        echo "The compressing of the dump failed (exit code $CODE), check for errors in the log."
        fail_healthcheck
        exit 1
    fi

    # Set permissions
    echo "Set dump file user and permissions..."
    chown ${PUID}:${PGID} "${DUMP_FILE}.gz"
    chmod 770 "${DUMP_FILE}.gz"
}

function main {
    echo "Dump script started."

    start_healthcheck

    check_environment_variables

    # Set default port
    if [ "${DUMPER_PORT}" = "**None**" ]; then
        if [ "${DUMPER_TYPE}" = "mysql" ]; then
            export DUMPER_PORT=3306
        fi
        if [ "${DUMPER_TYPE}" = "postgres" ]; then
            export DUMPER_PORT=5432
        fi
    fi

    # Set up postgres authentication
    if [ "${DUMPER_TYPE}" = "postgres" ]; then
        export PGPASSWORD="${DUMPER_PASSWORD}"
    fi

    create_dump

    clean_old_dumps

    stop_healthcheck

    echo "Dump script correctly completed."
}

main
