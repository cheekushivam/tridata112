#!/usr/bin/bash
# set -e
## Run from a specific line: bash <(sed -n '38,$p' cpd02.sh)
source $(dirname $(realpath ${0}))/env.sh
### DB2 Warehouse & DMC
### DB2W
cat <<EOF | oc apply -f -
oc create -f ${PROJECT_DIR}/manifests/db2ucatsrc.yaml
EOF
echo "Waiting for DB2 Catalog"
sleep 2
oc create -f ${PROJECT_DIR}/manifests/db2wsubs.yaml
echo "Waiting for DB2W Subscription"
sleep 1m
while \
[ "$(oc get csv -n ibm-common-services ibm-db2wh-cp4d-operator.v1.0.10 -o jsonpath='{ .status.phase } : { .status.message}')" != "Succeeded : install strategy completed with no errors" ]; \
do sleep 7; \
echo "Waiting for DB2Warehouse Operator to be created."; \
done
oc create -f ${PROJECT_DIR}/manifests/db2wcr.yaml
#sleep 2m
DB2WHSERVICE=$(oc get Db2whService db2wh-cr -n ibm-cpd -o jsonpath='{.status.db2whStatus}{"\n"}')
while [ "$DB2WHSERVICE" != "Completed" ]
  do
    for i in $(oc get sa -n ibm-cpd | grep -v NAME | awk '{print $1}'); do
      addSecretinSA $i
    done
    DB2WHSERVICE=$(oc get Db2whService db2wh-cr -n ibm-cpd -o jsonpath='{.status.db2whStatus}{"\n"}')
    echo "Installing DB2 Warehouse...Wait!..." $DB2WHSERVICE
    sleep 20
  done
### DMC
oc create -f ${PROJECT_DIR}/manifests/dmcsubs.yaml
echo "Waiting for DMC Subscription"
sleep 1m
oc create -f ${PROJECT_DIR}/manifests/dmccr.yaml
#sleep 1m
DMCSERVICE=$(oc get Dmcaddon dmc-addon -n ibm-cpd -o jsonpath='{.status.dmcAddonStatus}{"\n"}')
while [ "$DMCSERVICE" != "Completed" ]
  do
    for i in $(oc get sa -n ibm-cpd | grep -v NAME | awk '{print $1}'); do
      addSecretinSA $i
    done
    DMCSERVICE=$(oc get Dmcaddon dmc-addon -n ibm-cpd -o jsonpath='{.status.dmcAddonStatus}{"\n"}')
    echo "Installing Data Management Console...Wait!..." $DMCSERVICE
    sleep 20
  done