#!/usr/bin/bash
#set -e
## Ensure env is initialized
source $(dirname $(realpath ${0}))/env.sh
oc new-project ibm-tas
oc create -f ${PROJECT_DIR}/manifests/tasopr.yaml
echo "Waiting a minute for the TAS operator"
sleep 1m
oc create -f ${PROJECT_DIR}/manifests/tassubs.yaml
#sleep 3m
while [ "$TASSVC" != "Succeeded" ]; do TASSVC=$(oc get csv ibm-tririga.v11.2.0 -o jsonpath='{.status.phase}{"\n"}'); echo "Installing Tririga Operator..." $TASSVC; sleep 10; done
oc create secret docker-registry ibm-entitlement --docker-server=cp.icr.io --docker-username=cp --docker-password=${ENTITLEMENT_KEY} -n ibm-tas
export DB2W_CA_CERT=$(oc get secret -n ibm-cpd internal-tls -o jsonpath='{.data.ca\.crt}' | base64 -d)
echo "$DB2W_CA_CERT" | sed 's/^/     /' >> ${PROJECT_DIR}/manifests/tasdbsec.yaml
oc create -f ${PROJECT_DIR}/manifests/tasdbsec.yaml
echo "ca.crt: |" | sed 's/^/  /' >> ${PROJECT_DIR}/manifests/tasslssec.yaml
export SLS_CA=$(oc get secret -n ibm-sls sls-cert-client -o jsonpath='{.data.ca\.crt}' | base64 -d)
echo "$SLS_CA" | sed 's/^/    /' >> ${PROJECT_DIR}/manifests/tasslssec.yaml
echo "tls.crt: |" | sed 's/^/  /' >> ${PROJECT_DIR}/manifests/tasslssec.yaml
export SLS_TLS=$(oc get secret -n ibm-sls sls-cert-client -o jsonpath='{.data.tls\.crt}' | base64 -d)
echo "$SLS_TLS" | sed 's/^/    /' >> ${PROJECT_DIR}/manifests/tasslssec.yaml
echo "tls.key: |" | sed 's/^/  /' >> ${PROJECT_DIR}/manifests/tasslssec.yaml
export SLS_KEY=$(oc get secret -n ibm-sls sls-cert-client -o jsonpath='{.data.tls\.key}' | base64 -d)
echo "$SLS_KEY" | sed 's/^/    /' >> ${PROJECT_DIR}/manifests/tasslssec.yaml
oc create -f ${PROJECT_DIR}/manifests/tasslssec.yaml
export UDS_CRT=$(oc get secret -n ibm-common-services event-api-certs -o jsonpath='{.data.tls\.crt}' | base64 -d)
echo "$UDS_CRT" | sed 's/^/    /' >> ${PROJECT_DIR}/manifests/tasudssec.yaml
export UDSAPIKEY=$(oc get secret uds-api-key -n ibm-common-services --output="jsonpath={.data.apikey}" | base64 -d)
envsubst < ${PROJECT_DIR}/manifests/tasudssec.yaml | oc create -f -
envsubst < ${PROJECT_DIR}/manifests/tascr.yaml | oc create -f -
while [ "$TASCR" != "TRIRIGA Application Suite is ready" ]; do TASCR=$(oc get Tririga my-tririga -o jsonpath='{.status.conditions[0].message}{"\n"}'); echo "Installing Tririga Suite..." $TASCR; sleep 40; done
host=$(oc get route -n ibm-tas my-tririga | grep tririga | awk '{print $2}')
context=$(oc get route -n ibm-tas my-tririga | grep tririga | awk '{print $3}')
echo "TRIRIGA URL"
echo https://$host$context/index.html
echo "TRIRIGA Admin Console URL"
echo https://$host$context/html/en/default/admin
