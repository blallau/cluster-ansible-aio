#!/bin/bash

CONF_FILE=${HOME}/.cluster-ansible-aio-env
OS=$(cat ${CONF_FILE})

CAIO_DIR=${HOME}/work/GIT/cluster-ansible-aio

KAST_DIR=${HOME}/work/GIT/Thales/kast
KAST_BINARIES=/home/T0125936/work/Thales/binaries/
KAST_INV=/tmp/hosts
EXEC_ON_MASTER=true

# Virtu
WORKER_NB=1
# overlay interface
KUBE_NIC_NAME="eth1"

# DASHBOARD
DASHBOARD_ENABLED=false

# OFFLINE_MODE
OFFLINE=true

# NETWORK
#########
declare -A net_addr
net_addr['debian']=100
net_addr['centos']=101
net_addr['flatcar']=102

CNI_PLUGIN=calico

# MULTUS
MULTUS_ENABLED=false

# MULTUS_TECH="bridge"
# MULTUS_TECH="macvlan"
MULTUS_TECH="ipvlan"
MULTUS_DIR=${HOME}/work/GIT/multus-cni

WHEREABOUTS_DIR=${HOME}/work/GIT/whereabouts

# STORAGE
#########

# REGISTRY
REGISTRY_ENABLED=true

# MINIO
MINIO_ENABLED=false

# LONGHORN
LONGHORN_ENABLED=false

# OPENEBS
OPENEBS_ENABLED=false

# ROOK
ROOK_ENABLED=false
