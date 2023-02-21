#!/bin/bash
set -e
## Ensure env is initialized
source $(dirname $(realpath ${0}))/env.sh
oc new-project ibm-sls
export MONGODB_NAMESPACE=mongodb
export MONGODB_USERNAME=$(oc get secret -n $MONGODB_NAMESPACE my-mongodb-admin-admin -o jsonpath="{.data.username}" | base64 -d)
export MONGODB_PASSWORD=$(oc get secret -n $MONGODB_NAMESPACE my-user-password -o jsonpath="{.data.password}" | base64 -d)
envsubst < ${PROJECT_DIR}/manifests/slscred.yaml | oc apply -f -
oc -n ibm-sls create secret docker-registry ibm-entitlement --docker-server=cp.icr.io --docker-username=cp --docker-password=$ENTITLEMENT_KEY
oc apply -f ${PROJECT_DIR}/manifests/slsopr.yaml
while \
[ "$(oc get ClusterServiceVersion ibm-sls.v3.4.1 -o jsonpath='{ .status.phase } : { .status.message}')" != "Succeeded : install strategy completed with no errors" ]; \
do sleep 5; \
echo "Waiting for Suite License Services Operator to be created."; \
done
oc create -f ${PROJECT_DIR}/manifests/slsbootstrap.yaml
# export DOMAIN=$(oc get Ingress.config cluster -o jsonpath='{.spec.domain}')
oc apply -f ${PROJECT_DIR}/manifests/slscr.yaml
while \
[ "$(oc get licenseservice sls -n ibm-sls -o jsonpath='{.status.conditions[0].message}')" != "Suite License Service API is ready. GET https://sls.ibm-sls.svc/api/entitlement/config rc=200" ]; \
do sleep 45; echo "Waiting for License Service to be ready."; done