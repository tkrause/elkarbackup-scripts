# elkarbackup-scripts
Backup scripts for Elkarbackup jobs

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
Path: //backups/mysql
Description: MySQL Backups
Pre-script: MySQL Dump.sh
```

MySQL dumps will be copied to the "Path" field (example: /root/backups/mysql) and ElkarBackup will save this directory. If "Path" directory doesn't exist, it will be created on first execution.

### Non-Debian Distributions

This script logs in MySQL thanks to /etc/mysql/debian.cnf file. In non-debian based distributions follow next steps.

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
