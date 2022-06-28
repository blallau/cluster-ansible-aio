#!/bin/bash
set -x
set -e

. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_common.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh

OS='flatcar'
WORKER_NB=5
LB_NB=2

# INVENTORY
###########
generateInventory

# VM
####
cd ${CAIO_DIR}
${CAIO_DIR}/cluster-ansible-aio remove-virtual-nodes -e lb_nb=${LB_NB} -e worker_nb=${WORKER_NB} -e guest_os_distro=${OS} -e node_prefix=${OS} -e net_prefix=${OS::3} -v --yes-i-really-really-mean-it

# set +x
