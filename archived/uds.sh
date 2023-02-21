#!/bin/bash
set -e
## Ensure env is initialized
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