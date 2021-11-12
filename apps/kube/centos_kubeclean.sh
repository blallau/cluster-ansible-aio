#!/bin/bash
set -x
set -e

OS='centos'

############ DO NOT MOVE ###############
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_params.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh
############ DO NOT MOVE ###############

# INVENTORY
###########
generateInventory

cd ${KAST_DIR}
ansible-playbook -i ${KAST_INV} -u centos playbooks/kube_clean.yml

# set +x
