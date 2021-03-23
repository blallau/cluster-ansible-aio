#!/bin/bash

# INVENTORY
###########
generateInventory() {
    mkdir -p ${KAST_ENV}/group_vars/all

    cat > ${KAST_ENV}/group_vars/all/rook_ceph.yml << ENDOFFILE
ceph_local_storage_type: raw
ceph_useAllDevices: false
ceph_deviceFilter: ^vd[b-d]
ceph_normal_sized_disks: false

ceph_dashboard_enabled: true
ceph_monitoring_enabled: false

ceph_hostnetwork_enabled: false
ceph_public_network: 11.100.200.0/24
ceph_cluster_network: 11.100.210.0/24

ceph_multus_network_enabled: ${MULTUS_ENABLED}
ceph_multus_cluster_network: kube-system/cluster-conf
ceph_multus_public_network: kube-system/public-conf

cephfs_enabled: false
cephfs_erasurecoded_pool: false
cephfs_datapool_replica_size: 3
cephfs_metadatapool_replica_size: 3

ceph_rbd_enabled: true
ceph_rbd_replica_size: 3

ceph_crash_collector_enabled: false

ceph_rgw_enabled: false
ceph_rgw_erasurecoded_pool: false
ceph_rgw_metadatapool_replica_size: 3
ceph_rgw_replica_size: 3

ENDOFFILE

    cat > ${KAST_ENV}/group_vars/all/lb.yml << ENDOFFILE
lb_keepalived_enabled: $KUBE_HA
lb_keepalived:
  enable_script_security: true
  script_user: nobody
  shared_password: "{{ lookup('password', '/dev/null length=8 chars=ascii_letters') }}"
  vip:
    interface: ${KUBE_NIC_NAME}
    address: '11.100.150.2'
  vip_admin:
    interface: ${KUBE_NIC_NAME}
    address: '11.100.150.3'
  internal_interface: eth1
  virtual_router_id: 51
  unicast: true

ENDOFFILE

    cat > ${KAST_ENV}/group_vars/all/grafana.yml << ENDOFFILE
grafana_postgres_db_user: grafana
grafana_postgres_db_pass: TO-CHANGE

grafana_postgres_db_admin_user: postgres
grafana_postgres_db_admin_pass: "{{ postgres_db_password }}"

grafana_user: admin
grafana_password: TO-CHANGE

ENDOFFILE

    cat > ${KAST_ENV}/group_vars/all/iam.yml << ENDOFFILE
keycloak_postgres_enabled: true

keycloak_postgres_db_addr: kast-default-postgresql.{{ postgresql_ns }}.svc.cluster.local
keycloak_postgres_db_port: 5432
keycloak_postgres_db_name: keycloak

keycloak_postgres_db_user: keycloak
keycloak_postgres_db_pass: TO-CHANGE

keycloak_postgres_db_admin_user: postgres
keycloak_postgres_db_admin_pass: "{{ postgres_db_password }}"

keycloak_user: admin
keycloak_password: TO-CHANGE

keycloak_admin_user: secadmin
keycloak_admin_password: "{{ keycloak_password }}"

keycloak_audit_user: secauditor
keycloak_audit_password: TO-CHANGE

keycloak_maintainer_user: maintainer
keycloak_maintainer_password: TO-CHANGE

keycloak_operator_user: operator
keycloak_operator_password: TO-CHANGE

keycloak_sysadmin_user: sysadmin
keycloak_sysadmin_password: TO-CHANGE

keycloak_sysaudit_user: sysauditor
keycloak_sysaudit_password: TO-CHANGE
ENDOFFILE

    cat > ${KAST_ENV}/hosts << ENDOFFILE
[all:vars]
ansible_python_interpreter=/usr/bin/python3

kube_network_plugin=${CNI_PLUGIN}
nic=${KUBE_NIC_NAME}

kube_exec_on_master=${EXEC_ON_MASTER}

offline=${OFFLINE}
offline_binaries_folder=${KAST_BINARIES}

registry_storage={'filesystem': {'rootdirectory': '/data/registry'}}
registry_capacity_storage=10Gi

node_prefix=${OS}

kube_ha=${KUBE_HA}

postgresql_ns=sql-store
postgres_db_user=postgres
postgres_db_password=TO-CHANGE

[kube_master]
${OS}master1 internal_address=11.${net_addr[${OS}]}.150.11 kube_hostname=${OS}master1

[kube_worker]
$(
for node_num in `seq 1 $WORKER_NB`; do
echo ${OS}worker${node_num} internal_address=11.${net_addr[${OS}]}.150.2${node_num} kube_hostname=${OS}worker${node_num}
done
)

[lb]
$(
for node_num in `seq 1 $LB_NB`; do
echo ${OS}lb${node_num} internal_address=11.${net_addr[${OS}]}.150.3${node_num}
done
)

[kube:children]
kube_master
kube_worker

[containerd:children]
kube

[registry]
${OS}worker1 internal_address=11.${net_addr[${OS}]}.150.21 kube_hostname=${OS}worker1

[any]
${OS}master1 internal_address=11.${net_addr[${OS}]}.150.11 kube_hostname=${OS}master1

[ingress]
${OS}worker1 internal_address=11.${net_addr[${OS}]}.150.21 kube_hostname=${OS}worker1

[s3:children]
kube_master
kube_worker

[s3:vars]
s3_cpu_requests=1
s3_browser=true
s3_disk_per_node=4
s3_storage_dir=/data/s3

[ceph_osd:children]
kube_worker

[zk:children]
kube_worker

[kafka:children]
kube_worker

[postgresql]
${OS}worker1 internal_address=11.${net_addr[${OS}]}.150.21 kube_hostname=${OS}worker1

[elastic:children]
kube_worker

ENDOFFILE
}

retrieveArtifacts() {
    if [ "$OFFLINE" = true ]; then
        cd ${KAST_DIR}
        utils/resources-helper.sh download --components="containerd,kube,registry,s3_storage,distributed_storage,sql_db,iam" --to=${KAST_BINARIES}
    fi
}

iam() {
    # Install postgres
    cd ${KAST_DIR}
    ansible -i ${KAST_INV} postgresql -b -m file -a "path=/data/postgresql state=directory"
    ansible-playbook -i ${KAST_INV} playbooks/sql_db.yml

    # Install Keycloak
    cd ${KAST_DIR}/install/kast-initial
    ansible-playbook -i ${KAST_INV} tools/playbooks/iam_preinstall.yml

    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} -e keycloak_debug_enabled=true playbooks/iam.yml

    cd ${KAST_DIR}/install/kast-initial
    ansible-playbook -i ${KAST_INV} tools/playbooks/iam_postinstall.yml
}

calicoClient() {
# deploy calicoctl
    if [ "$CNI_PLUGIN" = 'calico' ]; then
        kubectl apply -f https://docs.projectcalico.org/manifests/calicoctl.yaml
        alias calicoctl="kubectl exec -i -n kube-system calicoctl -- /calicoctl"

        cat <<EOF | calicoctl create -f -
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: pool-test
spec:
  cidr: 192.168.192.0/19
  ipipMode: Never
  natOutgoing: true
  disabled: false
  nodeSelector: all()
EOF

    fi
}

Longhorn() {
    if [ "$LONGHORN_ENABLED" = true ]; then
        kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v0.8.0/deploy/longhorn.yaml

        USER=admin; PASSWORD=admin; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> /tmp/auth
        kubectl -n longhorn-system create secret generic basic-auth --from-file=/tmp/auth

        cat <<EOF | kubectl create -n longhorn-system -f -
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: longhorn-frontend
          servicePort: 80
EOF
    fi
}

Multus() {
    if [ "${MULTUS_ENABLED}" = true ]; then
        ## WHEREABOUTS BEGIN
        kubectl apply -f ${WHEREABOUTS_DIR}/doc/daemonset-install.yaml -f ${WHEREABOUTS_DIR}/doc/whereabouts.cni.cncf.io_ippools.yaml
        ## WHEREABOUTS END

        ## MULTUS BEGIN
        kubectl apply -f ${MULTUS_DIR}/images/multus-daemonset.yml

        if [ "${MULTUS_TECH}" = "macvlan" ]; then
            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: public-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eth2",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "range": "11.100.200.0/24",
        "range_start": "11.100.200.100",
        "range_end": "11.100.200.200",
        "gateway": "11.100.200.1",
        "log_file" : "/tmp/whereabouts-public.log",
        "log_level" : "debug"
      }
    }'
EOF

            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: cluster-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eth3",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "range": "11.100.210.0/24",
        "range_start": "11.100.210.100",
        "range_end": "11.100.210.200",
        "gateway": "11.100.210.1",
        "log_file" : "/tmp/whereabouts-cluster.log",
        "log_level" : "debug"
      }
    }'
EOF
        elif [ "${MULTUS_TECH}" = "ipvlan" ]; then
            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: public-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "ipvlan",
      "master": "eth2",
      "mode": "l2",
      "ipam": {
        "type": "whereabouts",
        "range": "11.100.200.0/24",
        "range_start": "11.100.200.100",
        "range_end": "11.100.200.200",
        "gateway": "11.100.200.1",
        "log_file" : "/tmp/whereabouts-public.log",
        "log_level" : "debug"
      }
    }'
EOF

            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: cluster-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "ipvlan",
      "master": "eth3",
      "mode": "l2",
      "ipam": {
        "type": "whereabouts",
        "range": "11.100.210.0/24",
        "range_start": "11.100.210.100",
        "range_end": "11.100.210.200",
        "gateway": "11.100.210.1",
        "log_file" : "/tmp/whereabouts-cluster.log",
        "log_level" : "debug"
      }
    }'
EOF
        elif [ "${MULTUS_TECH}" = "bridge" ]; then
            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: public-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "multus_br2",
      "ipam": {
        "type": "whereabouts",
        "range": "10.100.200.0/24",
        "range_start": "10.100.200.100",
        "range_end": "10.100.200.200",
        "gateway": "10.100.200.1",
        "log_file" : "/tmp/whereabouts-public.log",
        "log_level" : "debug"
      }
    }'
EOF

            cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: cluster-conf
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "multus_br3",
      "ipam": {
        "type": "whereabouts",
        "range": "10.100.210.0/24",
        "range_start": "10.100.210.100",
        "range_end": "10.100.210.200",
        "gateway": "10.100.210.1",
        "log_file" : "/tmp/whereabouts-cluster.log",
        "log_level" : "debug"
      }
    }'
EOF
        fi
    fi
}
