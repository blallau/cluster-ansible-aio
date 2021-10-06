#!/bin/bash
#set -x

# INVENTORY
###########
generateInventory() {
    echo "generateInventory"
    mkdir -p ${KAST_ENV}/group_vars/all

    cat > ${KAST_ENV}/group_vars/all/cilium.yml << ENDOFFILE
cilium_etcd_operator_enabled: ${CILIUM_ETCD_OPERATOR_ENABLED:-false}
cilium_hubble_enabled: true
cilium_hubble_ui_enabled: true
cilium_hubble_relay_enabled: true
cilium_hubble_ui_ingress_enabled: true
cilium_hubble_ui_domain: hubble.{{ domain | default('dpsc') }}
cilium_bpf_masquerade: true

cilium_native_routing: ${CILIUM_NATIVE_ROUTING}
cilium_native_routing_cidr: "{{ pod_network_cidr }}"

ENDOFFILE

    cat > ${KAST_ENV}/group_vars/all/gatekeeper.yml << ENDOFFILE
cluster_policy_deploy_defaults: true
gatekeeper_replicas: 1

ENDOFFILE

    cat > ${KAST_ENV}/group_vars/all/csi_ceph_rbd.yml << ENDOFFILE
csi_ceph_rbd_monitor_list:
  - "${CSI_CEPH_MONITOR_IP}:6789"
csi_ceph_rbd_cluster_id: ${CSI_CEPH_RBD_CLUSTER_ID}
csi_ceph_rbd_user_id: kastAdmin
csi_ceph_rbd_user_key: ${CSI_CEPH_RBD_USER_KEY}

ENDOFFILE

    cat > ${KAST_ENV}/group_vars/all/istio.yml << ENDOFFILE
mesh_test: true
mesh_ingress_gateway: true
mesh_egress_gateway: true
mesh_egress_gateway_replica_count: 1
mesh_access_log: true
mesh_allow_outbound: false
egress_class: prime
mesh_egress_gateway_node_selector: false
kiali_enable: ${NETWORK_MESH_UI_ENABLED}

ENDOFFILE

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

    cat > ${KAST_ENV}/group_vars/all/network_policies.yml << ENDOFFILE
masters_ip:
  admin:
    - 11.101.150.11
  tunl0:
    - 10.244.78.64

lbs_ip: []

workers_ip:
  tunl0:
    - 10.244.105.0
    - 10.244.79.192
    - 10.244.76.128

ENDOFFILE

    if [ "$CEPH_EXTERNAL" = true ]; then
        cat >> ${KAST_ENV}/group_vars/all/rook_ceph.yml << ENDOFFILE
ceph_is_external: ${CEPH_EXTERNAL}
rook_ceph_external_ns: rook-ceph-external
ceph_external_version: ${CEPH_EXTERNAL_VERSION}
rook_external_ceph_mon_data: ${ROOK_EXTERNAL_CEPH_MON_DATA}
rook_external_fsid: ${ROOK_EXTERNAL_FSID}

rook_external_username: ${ROOK_EXTERNAL_USERNAME}
rook_external_user_secret: ${ROOK_EXTERNAL_USER_SECRET}

rook_secret_csi_rbd_provisioner_userKey: ${CSI_RBD_PROVISIONER_SECRET}
rook_secret_csi_rbd_node_userKey: ${CSI_RBD_NODE_SECRET}
rook_secret_csi_cephfs_provisioner_adminKey: ${CSI_CEPHFS_PROVISIONER_SECRET}
rook_secret_csi_cephfs_node_adminKey: ${CSI_CEPHFS_NODE_SECRET}

ENDOFFILE

        if [ -n "$ROOK_EXTERNAL_ADMIN_SECRET" ]; then
            cat >> ${KAST_ENV}/group_vars/all/rook_ceph.yml << ENDOFFILE
rook_external_admin_secret: ${ROOK_EXTERNAL_ADMIN_SECRET}

ENDOFFILE
        fi
    fi

    cat > ${KAST_ENV}/group_vars/all/lb.yml << ENDOFFILE
lb_kube_api_enabled: true
lb_keepalived_enabled: $KUBE_HA
lb_keepalived:
  enable_script_security: true
  script_user: nobody
  shared_password: "{{ lookup('password', '/dev/null length=8 chars=ascii_letters') }}"
  vips:
    - name: vip
      enabled: true
      interface: ${KUBE_NIC_NAME}
      address: '11.101.150.2'
    - name: vip_admin
      enabled: true  # Enable vip admin if needed
      interface: ${KUBE_NIC_NAME}
      address: '11.101.150.3'
  internal_interface: eth1
  virtual_router_id: 51
  unicast: false

ENDOFFILE

    cat > ${KAST_ENV}/group_vars/all/local_volume_prov.yml << ENDOFFILE
local_volume_prov_mem_requests: 32Mi
local_volume_prov_cpu_requests: 0.01
local_volume_sc_conf:
  - sc_name: "local-pv-prov-tenant1"
    host_path: "/data/kubernetes/data-0"
  - sc_name: "local-pv-prov-tenant2"
    host_path: "/data/kubernetes/data-1"
  - sc_name: "local-pv-prov-tenant3"
    host_path: "/data/kubernetes/data-2"
ENDOFFILE

    cat > ${KAST_ENV}/group_vars/all/log.yml << ENDOFFILE
fluent_bit_mem_requests: 128M
fluent_bit_cpu_requests: 0.1
fluent_bit_mem_limits: 128M

# kubernetes audit files scanned : on or off
kube_audit: false

# kubernetes log files scanned : on or off
kube_log: true

# host system audit files scanned : on or off
audit_log: false

# host system log files scanned : on or off
system_log: true

# list of system files watched
logsystem_files_watched: '/var/log/messages'

ENDOFFILE

    cat > ${KAST_ENV}/group_vars/all/grafana.yml << ENDOFFILE
grafana_postgres_db_user: grafana
grafana_postgres_db_pass: TO-CHANGE

grafana_postgres_db_admin_user: postgres
grafana_postgres_db_admin_pass: "{{ postgres_db_password }}"

grafana_user: admin
grafana_password: TO-CHANGE

ENDOFFILE

    if [ "$ROOK_ENABLED" = true ]; then
    cat > ${KAST_ENV}/group_vars/all/dataiku.yml << ENDOFFILE
rook_ceph_block_storage: true

ENDOFFILE
    fi

    cat > ${KAST_ENV}/group_vars/all/iam.yml << ENDOFFILE
keycloak_debug_enabled: true

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

    cat > ${KAST_ENV}/group_vars/all/openebs.yml << ENDOFFILE
openebs_analytics_enabled: false
openebs_jiva_enabled: ${OPENEBS_JIVA_ENABLED}
openebs_cstor_enabled: ${OPENEBS_CSTOR_ENABLED}
openebs_ndm_enabled: ${OPENEBS_NDM_ENABLED}
openebs_localpv_provisioner_enabled: ${OPENEBS_LOCALPV_ENABLED}
openebs_zfs_localpv_enabled: false
openebs_lvm_localpv_enabled: false
openebs_nfs_provisioner_enabled: false

ENDOFFILE

    cat > ${KAST_ENV}/hosts << ENDOFFILE
[all:vars]
ansible_python_interpreter=/usr/bin/python3
#fqdn_as_hostname=true
ingress_metrics_enabled=false

kube_network_plugin=${CNI_PLUGIN}
wireguard_enabled=${WIREGUARD_ENABLED}

nic=${KUBE_NIC_NAME}
calico_mtu_iface_pattern=${KUBE_NIC_NAME}
calico_ipv4pool_vxlan=${CALICO_IPV4POOL:-Always}
calico_mode=vxlan

kube_exec_on_master=${EXEC_ON_MASTER}
#kubeadm_skip_phases=--feature-gates=EphemeralContainers=true

offline=${OFFLINE}
offline_binaries_folder=${KAST_BINARIES}

node_prefix=${OS}

kube_ha=${KUBE_HA}

postgres_db_user=postgres
postgres_db_password=TO-CHANGE

sso=false

#ingress_nginx_http_port=80
#ingress_nginx_https_port=443

[kube_master]
${OS}master1${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.11

[kube_worker]
$(
for node_num in `seq 1 $WORKER_NB`; do
echo ${OS}worker${node_num}${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.2${node_num}
done
)

$(
if [ $LB_NB -gt 0 ]
then
echo "[lb]"
fi
)
$(
for node_num in `seq 1 $LB_NB`; do
echo ${OS}lb${node_num}${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.3${node_num}
done
)

[kube:children]
kube_master
kube_worker

[containerd:children]
kube

[registry:children]
kube_worker

[registry:vars]
registry_cpu_requests=0.1
registry_storage={'filesystem': {'rootdirectory': '/data/registry'}}

[any]
${OS}master1 internal_address=11.${net_addr[${OS}]}.150.11

[elastic]
${OS}worker3${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.23

[elastic:vars]
es_metric_cpu_requests=0.25
es_metric_mem_requests=32Mi
es_cpu_requests=0.5
es_mem_requests=1512Mi
es_java_opts="-Xms1512m -Xmx1512m"

[git]
${OS}worker1${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.21

[git:vars]
git_cpu_requests=0.1
git_mem_requests=512Mi

[ingress]
${OS}worker1${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.21

[ingress_admin]
${OS}worker2${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.22

[postgresql]
$(
if [ $WORKER_NB -ge 4 ]
then
NB_MINIO=4
elif [ $WORKER_NB -ge 2 ]
then
NB_MINIO=2
fi
for node_num in `seq 1 ${NB_MINIO}`; do
echo ${OS}worker${node_num}${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.2${node_num}
done
)

[s3]
$(
if [ $WORKER_NB -ge 4 ]
then
NB_MINIO=4
elif [ $WORKER_NB -ge 2 ]
then
NB_MINIO=2
fi
for node_num in `seq 1 ${NB_MINIO}`; do
echo ${OS}worker${node_num}${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.2${node_num}
done
)

[s3:vars]
s3_cpu_requests=0.1
s3_mem_requests=500M
s3_browser=true
s3_disk_per_node=2
s3_storage_dir=/data/s3

[ceph_osd:children]
kube_worker

[zk:children]
kube_worker

[kafka:children]
kube_worker

[postgresql:vars]
postgresql_pgadmin=true
postgresql_cpu_requests=0.25
postgresql_mem_requests=0.5G
postgresql_ns=sql-store
postgresql_storage_size=10Gi
postgresql_storage_dir=/data/postgresql

[monitor]
${OS}worker2${DOMAIN} internal_address=11.${net_addr[${OS}]}.150.22

[monitor:vars]
kube_state_metrics_cpu_requests=0.25
kube_state_metrics_mem_requests=32Mi
prometheus_server_cpu_requests=0.25
prometheus_server_mem_requests=256Mi
prometheus_push_gateway_cpu_requests=0.25
prometheus_push_gateway_mem_requests=32Mi

[dataiku:children]
kube_worker

[vault:children]
kube_worker

ENDOFFILE
}

retrieveArtifacts() {
    if [ "$OFFLINE" = true ]; then
        cd ${KAST_DIR}
        utils/resources-helper.sh download --components="cluster_policy,containerd,csi_ceph,deployment,distributed_storage,document_storage,git,iam,ingress,kube,local_volume_prov,log_collect,mesh,monitor,openebs,registry,s3_storage,sql_db,tooling,vault" --to=${KAST_BINARIES}
    fi
}

retrieveDataArtifacts() {
    if [ "$OFFLINE" = true ]; then
        cd ${KAST_DATA_DIR}
        utils/resources-helper.sh download --components="dataiku" --to=${KAST_BINARIES}
    fi
}

snap_os() {
    user=${1}
    if [ "$SNAP_OS" == false ]; then
        return
    fi
    sleep 10
    cd ${CAIO_DIR}
    NODE_PREFIX=${OS} ./virtual-manage --snap-create ${user}_os
    sleep 60
}

snap_kube() {
    user=${1}
    if [ "$SNAP_KUBE" == false ]; then
        return
    fi
    sleep 10
    cd ${CAIO_DIR}
    NODE_PREFIX=${OS} ./virtual-manage --snap-create ${user}_kube
    sleep 60
}

snap_kube_apps() {
    user=${1}
    if [ "$SNAP_KUBE_APPS" == false ]; then
        return
    fi
    sleep 10
    cd ${CAIO_DIR}
    NODE_PREFIX=${OS} ./virtual-manage --snap-create ${user}_kube_apps
    sleep 60
}

install_kube() {
    user=${1}
    extra_vars=${2:-}

    echo "install_kube"

    if [ "$INSTALL_KUBE" == false ]; then
        return
    fi
    # LB
    ######
    if [ "$KUBE_HA" == true ] && [ "${LB_NB}" -gt "0" ]; then
        cd ${KAST_DIR}
        ansible lb -m package -i ${KAST_INV} -b -u ${user} -a "name=firewalld state=present"
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/lb_generic_beta.yml
    fi

    # # KUBE
    # ######
    retrieveArtifacts
    if [ "${MULTUS_ENABLED}" == true ] && [ "${MULTUS_TECH}" = "bridge" ]; then
        cd ${CAIO_DIR}
        ansible-playbook -i ${KAST_INV} -e os_default_user=${OS} apps/kube/bridge_net.yml
        # # NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}
        # sleep 30
    fi

    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} ${extra_vars} -u ${user} playbooks/containerd_install.yml
    if [ ! $? -eq 0 ]; then
        exit 1
    fi

    # sleep 60
    # cd ${CAIO_DIR}
    # NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-containerd
    # sleep 60
    # exit 1

    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} ${extra_vars} -u ${user} playbooks/kube.yml
    if [ ! $? -eq 0 ]; then
        exit 1
    fi
#     for worker_idx in `seq 1 $WORKER_NB`; do
# #        kubectl taint nodes centosworker${worker_idx} node.kubernetes.io/unreachable:NoExecute
#         kubectl taint nodes centosworker${worker_idx} node.kubernetes.io/not-ready:NoExecute
#     done
    cd ${CAIO_DIR}
    ansible-playbook -i ${KAST_INV} ${extra_vars} -e os_default_user=${OS} apps/kube/kube-cli.yml
    if [ ! $? -eq 0 ]; then
        exit 1
    fi

    # sleep 60
    # cd ${CAIO_DIR}
    # NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-kube
    # exit 0
}


install_kube_apps() {
    user=$1

    # # KUBE
    # ######
    retrieveArtifacts

    if [ "$INSTALL_KUBE_APPS" == false ]; then
        return
    else
        echo -en "Install summaries :"
        if [ "$DASHBOARD_ENABLED" == true ]; then
            echo -en "\t- Dasboard"
        fi
        if [ "$DOCUMENT_STORAGE_ENABLED" == true ]; then
            echo -en "\t- Document Storage"
        fi
        if [ "$GATEKEEPER_ENABLED" == true ]; then
            echo -en "\t- Gatekeeper"
        fi
        if [ "$GITEA_ENABLED" == true ]; then
            echo -en "\t- Gitea"
        fi
        if [ "$IAM_ENABLED" == true ]; then
            echo -en "\t- Iam"
        fi
        if [ "$LOCAL_PROV_ENABLED" == true ]; then
            echo -en "\t- Local provisioner"
        fi
        if [ "$LOG_ENABLED" == true ]; then
            echo -en "\t- Log collect"
        fi
        if [ "$LONGHORN_ENABLED" == true ]; then
            echo -en "\t- Longhorn"
        fi
        if [ "$LOG_SYSTEM_ENABLED" == true ]; then
            echo -en "\t- Log system"
        fi
        if [ "$MINIO_ENABLED" == true ]; then
            echo -en "\t- Minio"
        fi
        if [ "$MONITOR_ENABLED" == true ]; then
            echo -en "\t- Monitor"
        fi
        if [ "$MULTUS_ENABLED" == true ]; then
            echo -en "\t- Multus"
        fi
        if [ "$NETWORK_POLICIES_ENABLED" == true ]; then
            echo -en "\t- Network Policies"
        fi
        if [ "$NETWORK_MESH_ENABLED" == true ]; then
            echo -en "\t- Network Mesh"
        fi
        if [ "$OPENEBS_ENABLED" == true ]; then
            echo -en "\t- OpenEbs"
        fi
        if [ "$REGISTRY_ENABLED" == true ]; then
            echo -en "\t- Registry"
        fi
        if [ "$ROOK_ENABLED" == true ]; then
            echo -en "\t- Rook"
        fi
        if [ "$WIREGUARD_ENABLED" == true ]; then
            echo -en "\t- Wireguard"
        fi
    fi

    if [ "$MINIO_ENABLED" = true ]; then
        sed -i "/registry_storage/d" ${KAST_ENV}/hosts
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/s3_storage.yml
        # wget https://dl.min.io/client/mc/release/linux-amd64/mc
        # chmod +x mc
    fi

    if [ "$REGISTRY_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/registry.yml
    fi

    if [ "$LOCAL_PROV_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/local_volume_provisioner.yml
    fi

    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} -u ${user} playbooks/ingress.yml
    # ansible-playbook -i ${KAST_INV} -u ${user} -e ingress_ansible_group=ingress playbooks/ingress_generic_beta.yml
    # ansible-playbook -i ${KAST_INV} -u ${user} -e ingress_class=admin -e ingress_ansible_group=ingress_admin playbooks/ingress_generic_beta.yml

    if [ "$IAM_ENABLED" = true ] || [ "$GITEA_ENABLED" = true ] || [ "$POSTGRESQL_ENABLED" = true ]; then
        # Install postgres
        cd ${KAST_DIR}
        ansible -i ${KAST_INV} postgresql -u ${user} -b -m file -a "path=/data/postgresql state=directory"
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/sql_db.yml
    fi

    if [ "$GATEKEEPER_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/cluster_policy_install.yml
    fi

    if [ "$DASHBOARD_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/dashboard.yml
    fi

    if [ "$NETWORK_MESH_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/mesh.yml
    fi

    if [ "$NETWORK_POLICIES_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/network_policies.yml
        cd ${KAST_DATA_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/network_policies.yml
        cd ${KAST_DIR}
    fi

    # # deploy calicoctl
    # # calicoClient

    # # sleep 120
    # # cd ${CAIO_DIR}
    # # NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-${CNI_PLUGIN}
    # # sleep 10
    # # exit 1

    if [ "$DOCUMENT_STORAGE_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/document_storage.yml
    fi

    if [ "$IAM_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/iam.yml
    fi

     if [ "$GITEA_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/git.yml
    fi

    if [ "$MONITOR_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/monitor.yml
    fi
    if [ "$KIBANA_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/kibana.yml
    fi

    # # longhorn
    # Longhorn

    if [ "$OPENEBS_ENABLED" = true ]; then
        # helm repo add openebs https://openebs.github.io/charts
        # helm repo update
        # helm install openebs --namespace openebs openebs/openebs --create-namespace --set ndmOperator.enabled=false --set ndm.enabled=false --set snapshotOperator.enabled=true --set analytics.enabled=false --set localprovisioner.enabled=true --set jiva.enabled=true

        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/openebs.yml

        #helm install openebs --namespace openebs openebs/openebs --create-namespace
        #helm install openebs --namespace openebs openebs/openebs --create-namespace --set cstor.enabled=true

        # helm install openebs openebs/openebs --namespace openebs --create-namespace \
        #      --set cstor.enabled=true \
        #      --set analytics.enabled=false \
        #      --set legacy.enabled=false \
        #      --set jiva.enabled=true \
        #      --set openebs-ndm.enabled=true \
        #      --set localprovisioner.enabled=true \
        #      --set localpv-provisioner.enabled=true \
        #      --set snapshotOperator.enabled=false \
        #      --set zfs-localpv.enabled=true \
        #      --set lvm-localpv.enabled=true

        #kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
        # kubectl apply -f https://openebs.github.io/charts/cstor-operator.yaml
        # kubectl apply -f https://openebs.github.io/charts/zfs-operator.yaml
        # kubectl apply -f https://openebs.github.io/charts/lvm-operator.yaml
    fi

    # # Multus
    # Multus

    if [ "$ROOK_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/rook_ceph.yml
    fi

    if [ "$CSI_CEPH_RBD_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/ceph_csi.yml
    fi

    if [ "$LOG_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/log.yml
    fi
    if [ "$LOG_SYSTEM_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/log_system.yml
    fi

    if [ "$ARGO_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/deployment.yml
    fi

    if [ "$VAULT_ENABLED" = true ]; then
        cd ${KAST_DIR}
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/vault.yml
    fi

    # cd ${CAIO_DIR}
    # 360 KO
    # 420 ??
    # sleep 600
    # NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-${CNI_PLUGIN}-rook-ceph
}

install_kube_apps_data() {
    user=$1

    # # KUBE
    # ######
    retrieveDataArtifacts

    if [ "$INSTALL_KUBE_APPS_DATA" == false ]; then
        return
    fi

    cd ${KAST_DATA_DIR}
    if [ "$DATAIKU_ENABLED" = true ]; then
        ansible-playbook -i ${KAST_INV} -u ${user} playbooks/dataiku.yml
        # wget https://dl.min.io/client/mc/release/linux-amd64/mc
        # chmod +x mc
    fi
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
        kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.1.2/deploy/longhorn.yaml

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
