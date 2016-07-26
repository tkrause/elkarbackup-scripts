# MySQL Dump.sh

This script backups all your client's MySQL databases in individual files. After the first copy, only modified databases will be copied.

## Configuration

Script level configuration:

```
Client Pre-Script:    No
Client Post-Script:   No
Job Pre-Script:       Yes
Job Post-Script:      No
```

Create a New Job:

```
Name: MySQL
Path: /backups/mysql
Description: MySQL Backups
Pre-script: MySQL Dump.sh
```

MySQL dumps will be copied to the "Path" field (example: //backups/mysql) and ElkarBackup will save this directory. If "Path" directory doesn't exist, it will be created on first execution.

### Non-Debian Distributions

This script logs into MySQL thanks to /etc/mysql/debian.cnf file. In non-debian based distributions follow the steps below.

Generate file /root/.my.cnf:

```
[mysql]
user=root
password=1234

[mysqldump]
user=root
password=1234
```

Important: this file must have 400 permissions:

```
$ chmod 0400 /root/.my.cnf
```


# PostgreSQL Dump.sh

This script backups all your client's PostgreSQL databases in individual files. After the first copy, only modified databases will be copied.

## Configuration

Script level configuration:

```
Client Pre-Script:    No
Client Post-Script:   No
Job Pre-Script:       Yes
Job Post-Script:      No
```

Create a New Job:

```
Name: PostgreSQL
Path: /backups/pgsql
Description: PostgreSQL Backups
Pre-script: PostgreSQL Dump.sh
```

PostgreSQL dumps will be copied to the "Path" field (example: /backups/pgsql) and ElkarBackup will save this directory. If "Path" directory doesn't exist, it will be created on first execution.

### All Distributions

This script logs into PostgreSQL two different ways. The first is with a .psql.cnf file in the home directory of user used to log into the host. The second is with postgres without a password.

### Password Authentication with .psql.cnf (Recommended)

Generate file .psql.cnf in user home directory

Note: HOST and PORT are optional parameters

```
USER=root
PASS=1234
HOST=localhost
PORT=5432
```

Important: this file must have 400 permissions:

```
$ chmod 0400 .psql.cnf
```

### Password Authentication with default postgres user:

Modify pg_hba.conf add the following line

```
local   all             postgres                                trust
```

Restart PostgreSQL

```
service postgresql restart
```
