#!/usr/bin/bash
## CP4D Function
function addSecretinSA {
  if ! $(oc get sa $1 -n ibm-cpd -o jsonpath='{.imagePullSecrets}{"\n"}' | grep -q ibm-entitlement); then
    echo "Adding imagePullSecret ibm-entitlement to service account $1"
    oc patch serviceaccount/$1 -n ibm-cpd --type='json' -p='[{"op":"add","path":"/imagePullSecrets/-","value":{"name":"ibm-entitlement"}}]'
  fi
}
## Entitlement key from https://myibm.ibm.com/products-services/containerlibrary
export PROJECT_DIR="$HOME/tridata112"
export ENTITLEMENT_KEY=
export MONGO_PASSWORD=Passw0rdPassw0rd
## ---- You will fill the following later in the process.
export DB2W_INSTANCE_ID=1661646324241051
## File Storage
# export FILE_STORAGE=ocs-storagecluster-cephfs
export FILE_STORAGE=ibmc-file-gold-gid
# export FILE_STORAGE=managed-nfs-storage
## Block storage
# export BLOCK_STORAGE=ocs-storagecluster-ceph-rbd
export BLOCK_STORAGE=ibmc-block-gold
export UDS_STORAGE_CLASS=ibmc-block-bronze
#export UDS_STORAGE_CLASS=ocs-storagecluster-ceph-rbd