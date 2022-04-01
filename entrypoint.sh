#!/bin/sh

# Check env variables
if [ "${PUID}" = "**None**" ] || [ -z "${PUID}" ]; then
    echo "You need to set the PUID environment variable."
    exit 1
fi
if [ "${PGID}" = "**None**" ] || [ -z "${PGID}" ]; then
    echo "You need to set the PGID environment variable."
    exit 1
fi
if [ "${DUMPER_TYPE}" != "mysql" ] && [ "${DUMPER_TYPE}" != "postgres" ]; then
    echo "You need to set the DUMPER_TYPE environment variable to 'mysql' or 'postgres'."
    exit 1
fi
if [ -z "${DUMPER_SCHEDULE}" ]; then
    echo "${DUMPER_SCHEDULE}"
    echo "You need to set the DUMPER_SCHEDULE environment variable."
    exit 1
fi

# Set up mysql authentication
if [ "${DUMPER_TYPE}" = "mysql" ]; then
    # Create .my.cnf, see https://stackoverflow.com/questions/9293042/how-to-perform-a-mysqldump-without-a-password-prompt
    echo '[mysqldump]' > $HOME/.my.cnf
    echo "user=$DUMPER_USER" >> $HOME/.my.cnf 
    echo "password=$DUMPER_PASSWORD" >> $HOME/.my.cnf 
fi

# Add job to crontab
echo "$DUMPER_SCHEDULE /dump.sh > /proc/1/fd/1 2>/proc/1/fd/2" >/etc/crontabs/root
code=$?
if [ $code -ne 0 ]; then
    echo "Adding the job to crontab failed (exit status $code), check for errors in the log."
    exit 1
fi
echo "Job '$DUMPER_SCHEDULE /dump.sh' added to crontab."

# Set dumps folder permissions
echo "Set dumps folder user..."
chown ${PUID}:${PGID} /dumps

# Execute cron foreground
echo "Executing cron foreground..."
/usr/sbin/crond -f -l 8

