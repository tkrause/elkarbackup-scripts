#!/bin/bash
# set -u

#
# Name: PostgreSQL Dump.sh
# Description: This script backups all your local PostgreSQL databases in individual files
#              It will copy to Elkarbackup only the modified databases.
# Use:  JOB level -> Pre-Script
#       You will need to create .psql.cnf on each server this script is run on
#               in the home directory of the user Elkarbackup is logging in as.
#
#               Example:
#
#               USER=
#               PASS=
#

#ELKARBACKUP_URL = user@serverip:/path
URL=`echo $ELKARBACKUP_URL | cut -d ":" -f1`    # user@serverip
USER="${URL%@*}"                                # user
HOST="${URL#*@}"                                # host
DIR=`echo $ELKARBACKUP_URL | cut -d ":" -f2`    # path
TMP=/tmp/ebpgsqldump

SSH="ssh -i /var/lib/elkarbackup/.ssh/id_rsa -o StrictHostKeyChecking=no ${USER}@${HOST}"

PGCNFNAME=".psql.cnf"

# Defaults
PGUSER=postgres
PGPASS=
PGHOST=localhost
PGPORT=5432
PSQL=""
PDUMP=""

#
# Start of program...
#

if [ "${ELKARBACKUP_LEVEL}" != "JOB" ]; then
    echo "[ERROR] Only allowed at job level"
    exit 1
fi

if [ "$ELKARBACKUP_EVENT" != "PRE" ]; then
        echo "[ERROR] Only allowed to run at pre job level"
        exit 1
fi

# Get remote users home directory
HOMEDIR=$($SSH "getent passwd $USER | cut -d: -f6")
if [ ${HOMEDIR} ]; then
        echo "[INFO] Found home directory $HOMEDIR for $USER"
        PGCNF="${HOMEDIR}/${PGCNFNAME}"
else
        PGCNF="${PGCNFNAME}"
fi

# Test for config file, if we have one pull the username and password
echo "[INFO] Checking for $PGCNF..."
HASCONF=$($SSH "test -f $PGCNF && echo $?")
if [ ${HASCONF} ]; then
        echo "[INFO] Loading config..."
        PGCONF=$($SSH "cat $PGCNF")

        while IFS="=" read -r name value; do
                if [ $name == "USER" ]; then
                        PGUSER=$value
                elif [ $name == "PASS" ]; then
                        PGPASS=$value
                elif [ $name == "HOST" ]; then
                        PGHOST=$value
                elif [ $name == "PORT" ]; then
                        PGPORT=$value
                fi
        done <<< "${PGCONF}"

        # Check to make sure we can login with this config
        echo "[INFO] Testing login with config credentials..."
        TEST=$($SSH "export PGPASSWORD=$PGPASS; psql -U $PGUSER -h $PGHOST -p $PGPORT -t -c '\\q' && echo $?")
        if [ "${TEST}" ]; then
                echo "[INFO] Login successful. Using config login for backup"
                PSQL="export PGPASSWORD=\"$PGPASS\"; psql -U $PGUSER -h $PGHOST -p $PGPORT -t -c"
                PDUMP="export PGPASSWORD=\"$PGPASS\"; pg_dump -U $PGUSER -h $PGHOST -p $PGPORT"
        else
                echo "[WARNING] Unable to login using $PGCNF. Credientials are invalid"
        fi
else
        echo "[INFO] $PGCNF not found, skipping..."
fi

if [ ! "${PSQL}" ]; then
        echo "[INFO] Checking for fallback user postgres with no password..."
        TEST=$($SSH "psql -U postgres -t -c '\\q' && echo $?")
        if [ "${TEST}" ]; then
                echo "[INFO] Login successful. Using fallback credentials"
                PSQL='psql -U postgres -t -c'
                PDUMP='pg_dump -U postgres'
        else
                echo "[ERROR] No suitable login methods found for PostgreSQL"
                exit 1
        fi
fi

if [ "$ELKARBACKUP_EVENT" == "PRE" ]; then
    # If backup directory doesn't exist, create it
    TEST=$($SSH "test -d $DIR && echo $?")
    if [ ! ${TEST} ]; then
        echo "[INFO] Backup directory $DIR doesn't exist. Creating..."
        $SSH "mkdir -p $DIR"
    fi

    # If tmp directory doesn't exist, create it
    TEST=$($SSH "test -d $TMP && echo $?")
    if [ ! ${TEST} ]; then
        echo "[INFO] TMP directory $TMP doesn't exist. Creating..."
        $SSH "mkdir -p $TMP"
    fi

    # Get all databases list
    databases=$($SSH "$PSQL 'SELECT datname FROM pg_database WHERE datistemplate = false;'")
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
        echo "ERROR: $databases"
        exit 1
    else
                for db in $databases; do
                        # Dump it!
                        $SSH "$PDUMP $db > \"$TMP/$db.sql\""
                        # If we already have an old version...
                        TEST=$($SSH "test -f $DIR/$db.sql && echo $?")
                        if [ ${TEST} ]; then
                                # Diff
                                #echo "making a diff"
                                TEST=$($SSH "diff -q <(cat $TMP/$db.sql|head -n -1) <(cat $DIR/$db.sql|head -n -1) > /dev/null && echo $?")
                                #echo "diff result: [$TEST]"
                                # If Diff = false, copy tmp dump file
                                if [ ! ${TEST} ]; then
                                        $SSH "cp $TMP/$db.sql $DIR/$db.sql"
                                        echo "[INFO][$db.sql] Changes detected. New dump saved."
                                else
                                        echo "[INFO][$db.sql] No changes detected. Nothing to save."
                                fi
                        else
                                echo "[INFO][$db.sql] First dump created!"
                                $SSH "cp $TMP/$db.sql $DIR/$db.sql"
                        fi
                done
        fi
fi

exit 0
