#!/bin/bash
#set -e
## Ensure env is initialized
source $(dirname $(realpath ${0}))/env.sh
# git clone https://github.com/IBM/tas-db-prep.git
# cd tas-db-prep/cp4d-db2wh
# chmod +x *.sh
# oc project ibm-cpd
# sh prepareDB.sh c-db2wh-${DB2W_INSTANCE_ID}-db2u-0 TASDB tasdb SMALL
# cd ${PROJECT_DIR}

### Demo Data

DB_USERNAME=tridata
DEPLOYMENT_SIZE=SMALL
DB_NAME=TASDB

DB2WHPOD=$(oc get pods -n ibm-cpd | grep c-db2wh-${DB2W_INSTANCE_ID}-db2u | awk '{print $1}')
DB_SCHEMA=$( echo ${DB_USERNAME} | awk '{ print toupper($0) }')

oc project ibm-cpd

# Check if schema TRIDATA exists
oc cp schemacheck.sh $DB2WHPOD:/tmp
oc exec -ti $DB2WHPOD -- chmod 666 /tmp/schemacheck.sh
oc exec -ti $DB2WHPOD -- su - db2inst1 -c "sh /tmp/schemacheck.sh">schema.out
if grep -q "TRIDATA" schema.out
then
  echo "Schema TRIDATA already exists, skipping Database population.."
  exit 0
fi

echo "***** Copying Sales DB Backup file *****"
## - old - ## oc exec -ti $DB2WHPOD -- curl salesdb.s3.us-east.cloud-object-storage.appdomain.cloud/TRIDEMO.0.db2inst1.DBPART000.20210715220817.001 --output /mnt/bludata0/TRIDEMO.0.db2inst1.DBPART000.20210715220817.001
oc exec -ti $DB2WHPOD -- curl democore-cos-cos-standard.s3.us-east.cloud-object-storage.appdomain.cloud/TRIDEMO.0.db2inst1.DBPART000.20220608061222.001 --output /mnt/bludata0/TRIDEMO.0.db2inst1.DBPART000.20220608061222.001
oc cp salesdb-dbrestore.sh $DB2WHPOD:/mnt/bludata0
#oc exec -ti $DB2WHPOD -- chmod 666 /mnt/bludata0/TRIDEMO.0.db2inst1.DBPART000.20210715220817.001 /mnt/bludata0/salesdb-dbrestore.sh
oc exec -ti $DB2WHPOD -- chmod 666 /mnt/bludata0/TRIDEMO.0.db2inst1.DBPART000.20220608061222.001 /mnt/bludata0/salesdb-dbrestore.sh
oc exec -ti $DB2WHPOD -- sudo wvcli system disable -m "Disable HA before Db2 maintenance"
oc exec -ti $DB2WHPOD -- su - db2inst1 -c "sh /mnt/bludata0/salesdb-dbrestore.sh $DB_NAME"
oc exec -ti $DB2WHPOD -- sudo wvcli system enable -m "Enable HA after Db2 maintenance"

exit 0