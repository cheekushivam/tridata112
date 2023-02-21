#!/bin/sh

DB_NAME=${1}

db2 connect to $DB_NAME
db2 force application all
db2 terminate
db2 deactivate database $DB_NAME
db2stop force
db2start admin mode restricted access
echo "***** Starting Sales Data DB Restore, wait 15 min. *****"
db2 RESTORE DATABASE TRIDEMO FROM /mnt/bludata0 TAKEN AT 20210715220817 ON /mnt/blumeta0/db2/databases DBPATH ON /mnt/blumeta0/db2/databases INTO $DB_NAME WITHOUT ROLLING FORWARD WITHOUT PROMPTING
echo "***** DB Restore complete *****"
db2stop force
db2start
db2 activate db $DB_NAME
db2 connect to $DB_NAME
db2 GRANT DBADM ON DATABASE TO USER tridata
db2 GRANT SECADM ON DATABASE TO USER tridata
db2 GRANT ACCESSCTRL ON DATABASE TO USER tridata
db2 GRANT DATAACCESS ON DATABASE TO USER tridata
db2 GRANT DBADM ON DATABASE TO USER admin
db2 GRANT SECADM ON DATABASE TO USER admin
db2 GRANT ACCESSCTRL ON DATABASE TO USER admin
db2 GRANT DATAACCESS ON DATABASE TO USER admin

exit 0