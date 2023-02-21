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
