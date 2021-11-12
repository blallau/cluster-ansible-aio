#!/bin/bash

# INSTALL PARAMS
CREATE_INSTANCE=false
SNAP_OS=false
INSTALL_KUBE=false
SNAP_KUBE=false
INSTALL_KUBE_APPS=true
SNAP_KUBE_APPS=false

INSTALL_KUBE_APPS_DATA=true
RETRIEVE_ARTIFACTS=true

PROMPT_USER=false

# GENERAL PARAMS
OFFLINE=true
WORKER_NB=3
MASTER_NB=1

LB_NB=0
KUBE_HA=false

CNI_PLUGIN=calico
EXEC_ON_MASTER=false

# OTHER PARAMS
CONF_FILE=${HOME}/.cluster-ansible-aio-env
OS=$(cat ${CONF_FILE})
#DOMAIN=".mydomain.org"

CAIO_DIR=${HOME}/work/GIT/cluster-ansible-aio

KAST_DIR=${HOME}/work/GIT/Thales/kast
KAST_DATA_DIR=${HOME}/work/GIT/Thales/kast-data

KAST_BINARIES=${HOME}/work/Thales/binaries/

KAST_ENV=${HOME}/work/Thales/kast_env/
KAST_INV=${KAST_ENV}/hosts

# overlay interface
KUBE_NIC_NAME="eth1"

if [ "$KUBE_HA" == true ]; then
    LB_NB=2
fi

# DASHBOARD
###########
DASHBOARD_ENABLED=false

# AUTH
######
IAM_ENABLED=false

# NETWORK
#########
declare -A net_addr
net_addr['debian']=100
net_addr['centos']=101
net_addr['flatcar']=102

# CALICO
# CALICO_IPV4POOL="Always" by default
# CrossSubnet Never
# CALICO_IPV4POOL="Always"
CALICO_IPV4POOL="Always"

# CHAOS
CHAOS_ENABLED=true

# CILIUM
CILIUM_NATIVE_ROUTING=false
CILIUM_ETCD_OPERATOR_ENABLED=false

# WIREGUARD
WIREGUARD_ENABLED=false

# MULTUS
MULTUS_ENABLED=false
# MULTUS_TECH="bridge"
# MULTUS_TECH="macvlan"
MULTUS_TECH="ipvlan"
MULTUS_DIR=${HOME}/work/GIT/multus-cni

WHEREABOUTS_DIR=${HOME}/work/GIT/whereabouts

# NETWORK_POLICIES
NETPOL_ENABLED=true

# NETWORK_MESH
NETWORK_MESH_ENABLED=false
NETWORK_MESH_UI_ENABLED=false

# MONITORING
#############
KIBANA_ENABLED=false
# VM system LOGs, VM audit LOGS VM & metrics
LOG_SYSTEM_ENABLED=false
# KUBE LOGS and audit, system LOGS
LOG_ENABLED=false
# MONITOR
MONITOR_ENABLED=false

# SECURITY
#############
GATEKEEPER_ENABLED=false
VAULT_ENABLED=false

# DATA
######
ARGO_ENABLED=false
CLICKHOUSE_ENABLED=true
DATAIKU_ENABLED=false

# STORAGE
#########
if [ "$OFFLINE" == true ]; then
    # REGISTRY
    REGISTRY_ENABLED=true

    # MINIO
    MINIO_ENABLED=true
else
    # REGISTRY
    REGISTRY_ENABLED=false

    # MINIO
    MINIO_ENABLED=false
fi

CASSANDRA_ENABLED=false
# Elastic
DOCUMENT_STORAGE_ENABLED=false
GITEA_ENABLED=false
KAFKA_ENABLED=false
LOCAL_PROV_ENABLED=false
POSTGRESQL_ENABLED=false

if [ "$LOG_ENABLED" = true ] || [ "$LOG_SYSTEM_ENABLED" = true ]; then
    # DOCUMENT_STORAGE
    DOCUMENT_STORAGE_ENABLED=true
fi

# LONGHORN
LONGHORN_ENABLED=false

# OPENEBS
OPENEBS_ENABLED=false
OPENEBS_JIVA_CSI=false

if [ "$OPENEBS_ENABLED" == true ]; then
    if [ "$OPENEBS_JIVA_CSI" == true ]; then
        OPENEBS_CSTOR_ENABLED=false
        OPENEBS_JIVA_ENABLED=true
        OPENEBS_NDM_ENABLED=false
        OPENEBS_LOCALPV_ENABLED=true
    elif [ "$OPENEBS_CSTOR_CSI" == true ]; then
        OPENEBS_CSTOR_ENABLED=true
        OPENEBS_JIVA_ENABLED=false
        OPENEBS_NDM_ENABLED=true
        OPENEBS_LOCALPV_ENABLED=true
    fi
fi


# ROOK
ROOK_ENABLED=false
# export ROOK_EXTERNAL_FSID="6f63f5f8-b33e-11eb-bba6-525400322301"
# export ROOK_EXTERNAL_CEPH_MON_DATA="centosworker3=11.101.100.23:3300"

# export ROOK_EXTERNAL_USER_SECRET="AQAYBJxgCq2zKBAATLscEXnQWQDJfz1b3Oqs9g=="
# export ROOK_EXTERNAL_USERNAME="client.healthchecker"
# export CEPH_EXTERNAL_VERSION="v15.2.11"
# # To comment
# export ROOK_EXTERNAL_ADMIN_SECRET="AQAqAZxgwPagHhAAEQb/wWRGpMXMEHar5ReMFA=="

# CSI_CEPH_RBD
CSI_CEPH_RBD_ENABLED=false
# export CSI_RBD_NODE_SECRET="AQAYBJxghxwvORAAJNfJ5raZ761E/A4sLDmUBw=="
# export CSI_RBD_PROVISIONER_SECRET="AQAZBJxgFtXoDRAAzijj1z2n4PbJ9BaNFwoueg=="
# export CSI_CEPHFS_NODE_SECRET="AQAZBJxgtBBgHhAApaTtR4tkdBT/SSKlBTeWgQ=="
# export CSI_CEPHFS_PROVISIONER_SECRET="AQAZBJxgmN0XMBAAreIQOIPU2kXRS3jYjImJIg=="
# ceph mon dump

# ceph fsid
export CSI_CEPH_RBD_CLUSTER_ID="b2673848-e3ee-11eb-9294-525400322401"
# sudo ceph auth get-or-create-key client.kastAdmin mon 'profile rbd' osd 'profile rbd pool=kastCsiPool'
export CSI_CEPH_RBD_USER_KEY="AQCDse1gagDFFBAAAJOZQlCynIcKQcU3EUDnHg=="
export CSI_CEPH_MONITOR_IP="11.101.100.24"

CEPH_EXTERNAL=false
