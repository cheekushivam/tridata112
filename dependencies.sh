#!/bin/bash
###!/usr/bin/bash
set -e
## Ensure env is initialized
source $(dirname $(realpath ${0}))/env.sh

oc new-project mongodb
git clone https://github.com/mongodb/mongodb-kubernetes-operator.git
oc create -f mongodb-kubernetes-operator/config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml
oc apply -k mongodb-kubernetes-operator/config/rbac/
oc create -f ${PROJECT_DIR}/manifests/manager.yaml
mkdir ${PROJECT_DIR}/mongo_certs ; cd $_
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -reqexts v3_req -extensions v3_ca -out ca.crt -subj "/C=US/ST=NY/L=New York/O=AIAPPS/OU=TAS/CN=TAS"
oc create secret tls ca-key-pair --cert=ca.crt --key=ca.key -n mongodb
oc create configmap custom-ca --from-file=ca.crt -n mongodb
cd ..
envsubst < ${PROJECT_DIR}/manifests/mongosec.yaml | oc create -f -
envsubst < ${PROJECT_DIR}/manifests/mongocr.yaml | oc create -f -
MONGOSVC=$(oc get MongoDBCommunity my-mongodb -o jsonpath='{.status.phase}{"\n"}')
while [ "$MONGOSVC" != "Running" ]; do MONGOSVC=$(oc get MongoDBCommunity my-mongodb -o jsonpath='{.status.phase}{"\n"}'); echo "Installing MongoDB..." $MONGOSVC; sleep 20; done
### SLS
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
### UDS
source $(dirname $(realpath ${0}))/env.sh
oc project ibm-common-services
oc create secret docker-registry ibm-entitlement --docker-server=cp.icr.io --docker-username=cp --docker-password="$ENTITLEMENT_KEY" -n ibm-common-services
oc apply -f ${PROJECT_DIR}/manifests/iuds.yaml
while \
[ "$(oc get csv -n ibm-common-services user-data-services-operator.v2.0.8 -o jsonpath='{ .status.phase } : { .status.message}')" != "Succeeded : install strategy completed with no errors" ]; \
do sleep 5; \
echo "Waiting for UDS Operator to be created."; \
done
oc create secret generic database-credentials -n ibm-common-services --from-literal=db_username=basuser --from-literal=db_password=admin
oc create secret generic grafana-credentials -n ibm-common-services --from-literal=grafana_username=basuser --from-literal=grafana_password=admin
envsubst < ${PROJECT_DIR}/manifests/udscr.yaml | oc apply -f -
while \
[ "$(oc get AnalyticsProxy analyticsproxy -n ibm-common-services -o template --template {{.status.phase}})" != "Ready" ]; \
do sleep 45; \
echo "Waiting for AnalyticsProxy to be created. This could take 45 minutes."; \
done
oc apply -f ${PROJECT_DIR}/manifests/udskey.yaml
sleep 1m
while \
[ "$(oc get GenerateKeys uds-api-key -n ibm-common-services -o template --template {{.status.phase}})" != "Ready" ]; \
do sleep 5; \
echo "Waiting for UDS API key to be created."; \
done