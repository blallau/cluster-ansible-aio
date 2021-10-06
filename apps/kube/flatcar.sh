#!/bin/bash
set -x
set -e

echo flatcar > ~/.cluster-ansible-aio-env

. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_common.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh

# INVENTORY
###########
generateInventory

# VM
####
cd ${CAIO_DIR}
${CAIO_DIR}/cluster-ansible-aio create-virtual-nodes -s preflight -e lb_nb=${LB_NB} -e worker_nb=${WORKER_NB} -e docker_enabled=false -e guest_os_distro=${OS} -e os_default_user=core -e node_prefix=${OS} -e net_prefix=${OS::3} -e net_second_octet=${net_addr[${OS}]} -v

# KUBE
######
cd ${KAST_DIR}
ansible-playbook -e coreos_locksmithd_disable=false -i ${KAST_INV} -u core playbooks/preflight_flatcar.yml

retrieveArtifacts

extra_vars="-e ansible_python_interpreter='/opt/bin/python'"

if [ "$LB_NB" -gt "0" ]; then
    cd ${KAST_DIR}
    ansible-playbook  -i ${KAST_INV} -u core playbooks/lb.yml
fi

install_kube core "\${extra_vars}"
