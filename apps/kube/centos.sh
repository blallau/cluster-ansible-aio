#!/bin/bash
set -x
set -e

echo centos > ~/.cluster-ansible-aio-env

. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_common.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh

OFFLINE=true
WORKER_NB=3
OS='centos'
KUBE_HA=false

ROOK_ENABLED=true
IAM_ENABLED=false

# INVENTORY
###########
generateInventory

# # VM
# ####
# cd ${CAIO_DIR}
# ${CAIO_DIR}/cluster-ansible-aio create-virtual-nodes -s preflight -e lb_nb=${LB_NB} -e worker_nb=${WORKER_NB} -e docker_enabled=false -e guest_os_distro=${OS} -e node_prefix=${OS} -e net_prefix=${OS::3} -e net_second_octet=${net_addr[${OS}]} -v

# # sleep 10
# # cd ${CAIO_DIR}
# # NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}
# # sleep 60
# # exit 1

# install_kube "centos"

# sleep 10
# cd ${CAIO_DIR}
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-kube
# sleep 60

install_kube_apps "centos"
