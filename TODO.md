Bug Fix/Todo list
-----------------
- In case of many interfaces add check to have ext interface in first position
- manage node-prefix in SSH keys and libvirt network, ... in order to not remove env from previous deployment
- remove shutdown before snapshot => use fsfreeze before snapshot ?
- remove name or bridge in net_interfaces (redondant info)
- fix gracefully-shutdown
- add task to wait for Flatcar VMs ready
- fix bug when different deployments use the same networks
  => IPs/macs association cannot be set in the previous DHCP config
  => IPs are random => hence deployment fails [Waiting on IPs]
- manage idempotency when playbook is running twice
- remove specific code (master, worker, lb,) from nodes.j2
  => code must be generic
- [manage QCOW2 with a baseimagefile]
- [Fix DNS issue when using Docker DNS server instead of Libvirt dnsmasq]
- [automaticaly retrieve last iso images (debian,centos), to avoid too long package update]
- [manage remote libvirtd]


check https://github.com/hicknhack-software/ansible-libvirt

- fix SNAP_NAME and SNAPSHOT_NAME redondancy
