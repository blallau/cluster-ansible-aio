#!/bin/bash
set -x
set -e

. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_common.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh

OS='flatcar'

# INVENTORY
###########
generateInventory

# VM
####
cd ${CAIO_DIR}
${CAIO_DIR}/cluster-ansible-aio create-virtual-nodes -e worker_nb=${WORKER_NB} -e docker_enabled=false -e guest_os_distro=${OS} -e os_default_user=core -e node_prefix=${OS} -e net_prefix=${OS::3} -e net_second_octet=${net_addr[${OS}]} -v
sleep 10

sleep 10
cd ${CAIO_DIR}
NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}
sleep 60
exit 1

# KUBE
######

cd ${CAIO_DIR}
ansible-playbook -i ${KAST_INV} -e coreos_locksmithd_disable=false apps/kube/bootstrap-flatcar.yml

retrieveArtifacts

cd ${KAST_DIR}
ansible-playbook -e ansible_python_interpreter="/opt/bin/python" -i ${KAST_INV} playbooks/containerd_install.yml

sleep 60
cd ${CAIO_DIR}
NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-containerd
sleep 60

cd ${KAST_DIR}
ansible-playbook -e ansible_python_interpreter="/opt/bin/python" -e kube_binaries_path="/opt/bin" -i ${KAST_INV} playbooks/kube.yml -vv
