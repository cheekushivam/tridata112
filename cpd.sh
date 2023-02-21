#!/usr/bin/bash
# set -e
## Run from a specific line: bash <(sed -n '59,$p' cp4d_409_1.sh)
source $(dirname $(realpath ${0}))/env.sh
### Common Services - Cert Manager & CP4D Control Plane
#### IBM Operator Catalog Source
oc create -f ${PROJECT_DIR}/manifests/icatsrc.yaml
echo "Waiting a few minutes ... IBM's Operator Catalog"
sleep 3m
#### Create Projects
oc new-project ibm-cpd
#### Create entitlement key secret
oc create secret docker-registry ibm-entitlement --docker-server=cp.icr.io --docker-username=cp --docker-password=${ENTITLEMENT_KEY} -n ibm-cpd
oc new-project ibm-common-services
### IBM Common Services Operator Group and Subscription
oc create -f ${PROJECT_DIR}/manifests/icsgroupsubs.yaml
echo "Waiting a few minutes ... IBM Common Services"
sleep 1m
while \
[ "$(oc get commonservice common-service -n ibm-common-services -o template --template {{.status.overallStatus}})" != "Succeeded" ]; \
do sleep 10; \
echo "Waiting for IBM Common Services to be created."; \
done
#### Cert Manager
oc create -f ${PROJECT_DIR}/manifests/icertmgr.yaml
sleep 1m
while \
[ "$(oc get certmanager default -n ibm-common-services -o template --template {{.status.certManagerStatus}})" != "Successfully deployed cert-manager" ]; \
do sleep 7; \
echo "Waiting for IBM Cert Manager to be created."; \
done
#### CP4D Project
oc project ibm-cpd
#### CP4D Subscription
oc create -f ${PROJECT_DIR}/manifests/icpdsubs.yaml
echo "Waiting for CP4D subscription"
sleep 1m
while \
[ "$(oc get csv -n ibm-common-services cpd-platform-operator.v2.0.8 -o jsonpath='{ .status.phase } : { .status.message}')" != "Succeeded : install strategy completed with no errors" ]; \
do sleep 7; \
echo "Waiting for CP4D Operator to be created."; \
done
#### CP4D empty OperandRequest for Namespace
oc create -f ${PROJECT_DIR}/manifests/iemptyopr.yaml
echo "Waiting for OperandRequest"
sleep 5
#### CP4D Control Plane CR
envsubst < ${PROJECT_DIR}/manifests/icpdcr.yaml | oc create -f -
echo "Waiting for CP4D Control Plane"
# sleep 2m
ZENSERVICE=$(oc get ZenService lite-cr -n ibm-cpd -o jsonpath="{.status.zenStatus}{'\n'}")
while [ "$ZENSERVICE" != "Completed" ]
  do
    for i in $(oc get sa -n ibm-cpd | grep -v NAME | awk '{print $1}'); do
      addSecretinSA $i
    done
    ZENSERVICE=$(oc get ZenService lite-cr -n ibm-cpd -o jsonpath="{.status.zenStatus}{'\n'}")
    echo "Installing Cloud Pak for Data Control Plane...Wait!..." $ZENSERVICE
    sleep 20
  done
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