#!/bin/bash

NODE_PREFIX=""
SERVICES="${NODE_PREFIX}controller-1 ${NODE_PREFIX}node-1 ${NODE_PREFIX}node-2"
SNAPSHOT_NAME=""
TIMEOUT=300

function start {
    docker start docker-dnsmasq
    for service in $SERVICES; do
        virsh start $service
    done
}

function destroy {
    for service in $SERVICES; do
        virsh destroy $service
    done
}

function undefine {
    for service in $SERVICES; do
        virsh undefine $service
    done
}

function list_running_domains() {
    virsh list | grep "running" | awk '{ print $2}'
}

function gracefully_shutdown {
	echo "Try to cleanly shut down all running KVM domains..."

	# Try to shutdown each domain, one by one.
	list_running_domains | while read DOMAIN; do
		# Try to shutdown given domain.
		virsh shutdown $DOMAIN --mode acpi
	done

	# Wait until all domains are shut down or timeout has reached.
	END_TIME=$(date -d "$TIMEOUT seconds" +%s)

	while [ $(date +%s) -lt $END_TIME ]; do
		# Break while loop when no domains are left.
		test -z "$(list_running_domains)" && break
		# Wait a litte, we don't want to DoS libvirt.
		sleep 1
	done

	# Clean up left over domains, one by one.
	list_running_domains | while read DOMAIN; do
		# Try to shutdown given domain.
		virsh destroy $DOMAIN
		# Give libvirt some time for killing off the domain.
		sleep 3
	done
}

function snap-create {
    gracefully_shutdown
    for service in $SERVICES; do
        virsh snapshot-create-as --domain $service --name $SNAPSHOT_NAME
        echo "Domain $service snapshoted"
    done
    start
}

function snap-delete {
    for service in $SERVICES; do
        virsh snapshot-delete $service --snapshotname $SNAPSHOT_NAME
    done
}

function snap-revert {
    destroy
    for service in $SERVICES; do
        virsh snapshot-revert $service --snapshotname $SNAPSHOT_NAME
    done
    start
}

function snap-list {
    for service in $SERVICES; do
        virsh snapshot-list $service
    done
}

function usage {
    cat <<EOF
Usage: $0 COMMAND

Commands:
    --purge                          Purge cluster
    --start                          Start cluster
    --shutdown                       Shutdown cluster
    --snap-create <snapshot name>    Create cluster snapshot
    --snap-delete <snapshot name>    Delete cluster snapshot
    --snap-revert <snapshot name>    Revert cluster snapshot
    --snap-list                      List cluster snapshots
EOF
}

LONG_OPTS="purge,start,shutdown,snap-delete:,snap-create:,snap-revert:,snap-list,help"
ARGS=$(getopt -l "${LONG_OPTS}" --name "$0" -- "$@") || { usage >&2; exit 2; }

while [ "$#" -gt 0 ]; do
    case "$1" in
    (--purge)
        destroy
        undefine
        exit 0
        ;;
    (--start)
        start
        exit 0
        ;;
    (--shutdown)
        gracefully_shutdown
        exit 0
        ;;
    (--snap-delete)
        SNAPSHOT_NAME=$2
        shift 2
        snap-delete
        exit 0
        ;;
    (--snap-create)
        SNAPSHOT_NAME=$2
        shift 2
        snap-create
        exit 0
        ;;
    (--snap-revert)
        SNAPSHOT_NAME=$2
        shift 2
        snap-revert
        exit 0
        ;;
    (--snap-list)
        snap-list
        exit 0
        ;;
    (--help|-h)
        usage
        exit 0
        ;;
    (*)
        usage
        exit 3
        ;;
esac
done
