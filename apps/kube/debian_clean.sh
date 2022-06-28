#!/bin/bash
set -x
set -e

OS='debian'

############ DO NOT MOVE ###############
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_params.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh
############ DO NOT MOVE ###############

# INVENTORY
###########
generateInventory

# VM
####

cd ${CAIO_DIR}
${CAIO_DIR}/cluster-ansible-aio remove-virtual-nodes -e lb_nb=${LB_NB} -e worker_nb=${WORKER_NB} -e guest_os_distro=${OS} -e node_prefix=${OS} -e net_prefix="" -v --yes-i-really-really-mean-it

# set +x
