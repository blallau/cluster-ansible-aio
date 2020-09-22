#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright 2016 William Leemans <willie@elaba.net>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

DOCUMENTATION = '''
---
author: William Leemans
module: virt_volume
short_description: Create and remove libvirt Storage Volumes
description:
  - This module allows for creating, wiping and removing Storage Volumes
  - This module requires the libvirt python module
version_added: 2.1
options:
  capacity:
    description:
      - The size of the storage volume
        default in bytes or optionally with one of [bBsSkKmMgGtTpPeE] units
        Float values must begin with a digit.
  exclude_pool:
    description:
      - exclude pools based on regular expression
    required: false
  refresh_pool:
    default: true
    description:
      - refresh the pool before parsing the pool information
    required: false
  format:
    default: raw
    description:
      - The storage volume format
    required: false
  name:
    description:
      - The name of the storage volume to be created/wiped/removed
    required: true
  pool:
    description:
      - The name of the storage pool to create/wipe/remove a storage volume in/from
    required: false
  state:
    choices: [ 'present', 'absent', 'wipe' ]
    default: present
    description:
      - Create, remove, wipe the storage volume
    required: true
  strategy:
    choices: [ "least", "most", "random" ]
    default: least
    description:
      - The strategy used to create a storage volume on a storage pool if the pool name is not given.
        least: Least used (in bytes) storage pool
        most: most used (in bytes) storage pool
        random: randomly chosen
    required: false
'''

EXAMPLES = '''
# Create a storage volume MyVolume of 5G in the least used storage pool
- action: virt_volume name=MyVolume capacity=5G state=present strategy=least

# Create a storage volume MyVolume of 2G in storage pool MyPool
- action: virt_volume name=MyVolume pool=MyPool capacity=2G state=present

# Wipe storage volume MyVolume on storage pool MyPool
- action: virt_manage name=MyVolume pool=MyPool state=wipe

# delete storage volume MyVolume on storage pool MyPool
- action: virt_manage name=MyVolume pool=MyPool state=absent
'''

import sys
import random
import xml.dom.minidom

try:
    import libvirt
except ImportError:
    print("failed=True msg='libvirt python module unavailable'")
    sys.exit(1)

try:
    import xml.etree.ElementTree as ET
except ImportError:
    try:
        import elementtree.ElementTree as ET
    except ImportError:
        print("failed=True msg='ElementTree python module unavailable'")
        sys.exit(1)

def sizeToBytes(size):
    valid_units = [ 'b', 'k', 'm', 'g', 't', 'p', 'e', 'z', 'y' ]

    if size is None:
        return False
    size = str(size)
    unit = size[-1:].lower()
    if not unit.isdigit():
        if unit not in valid_units:
            return False
        size = float(size[0:-1])
    else:
        unit = 'b'
        size = float(size)

    for u in valid_units:
        if unit == u:
            break
        size = size * 1024
    return int(size)

def main():
    module = AnsibleModule(
        argument_spec = dict(
            capacity     = dict(required = False, default = None),
            exclude_pool = dict(required = False, type = 'str', default = None),
            refresh_pool = dict(required = False, type = 'bool', default = True),
            ### FIXME: add various formats a choices here
            format       = dict(default = 'raw', type = 'str'),
            name         = dict(required = False, type = 'str', default = None),
            pool         = dict(default = None, required = False, type = 'str'),
            state        = dict(required = False, default = 'present', choices = [ 'present', 'absent', 'wipe' ]),
            strategy     = dict(default = 'least', type = 'str', choices = [ 'least', 'most', 'random' ]),
            uri          = dict(default = 'qemu:///system', type= 'str', required = False ),
        ),
        supports_check_mode = True
    )

    pool_name = module.params.get('pool')
    exclude_pool = module.params.get('exclude_pool')
    refresh_pool = module.params.get('refresh_pool')
    state = module.params.get('state')
    strategy = module.params.get('strategy')
    vol_capacity = module.params.get('capacity')
    vol_format = module.params.get('format')
    vol_name = module.params.get('name')
    uri = module.params.get('uri')

    try:
        server = libvirt.open(uri)
    except libvirt.libvirtError as e:
        module.fail_json(msg=str(e))

    if not server:
        module.fail_json(msg="Hypervisor connection failure.")

    result = dict(
        vol_info = dict(
            vol_name = vol_name,
            pool_name = pool_name,
            vol_path = None,
            vol_format = vol_format,
            vol_capacity = vol_capacity
            )
    )

    if state == "present":
        vol_capacity = sizeToBytes(vol_capacity)
        if vol_capacity is False:
            module.fail_json(msg="Bad capacity specification of '%s'." % module.params.get('capacity'))

        ### Get pool name according to strategy
        if pool_name is None:
            valid_pools = []
            for p in server.listAllStoragePools(flags=0):
                if p.isActive():
                   if refresh_pool:
                      p.refresh(flags=0)
                   pool_available = p.info()[3]
                   if re.match(exclude_pool, p.name()) is None and pool_available >= vol_capacity:
                       valid_pools.append({'name': p.name(), 'available': pool_available})

            p_used = None
            if strategy == 'least':
                for p in valid_pools:
                    if p_used is None:
                        p_used = p
                    elif p["available"] < p_used["available"]:
                        p_used = p
            elif strategy == 'most':
                for p in valid_pools:
                    if p_used is None:
                        p_used = p
                    elif p["available"] > p_used["available"]:
                        p_used = p
            elif strategy == 'random':
                p_used = random.choice(valid_pools)
            else:
                module.fail_json(msg="Unknown strategy: %s" % strategy)

            if p_used is None:
               module.fail_json(msg="Could not detect a pool with enough free diskspace.")

            pool_name = p_used["name"]

        p = server.storagePoolLookupByName(pool_name)

        if p.info()[3] < vol_capacity:
           module.fail_json(msg="Pool %s does not have enough free space." % pool_name)

        if vol_name in p.listVolumes():
            v = p.storageVolLookupByName(vol_name)
            try:
                vol_format = ET.fromstring(v.XMLDesc(0)).find('./target/format').attrib['type']
            except:
                vol_format = 'unknown'

            result['changed'] = False
            result['vol_info']['pool_name'] = p.name()
            result['vol_info']['vol_path'] = v.path()
            result['vol_info']['vol_format'] = vol_format
            result['vol_info']['vol_capacity'] = v.info()[1]
            module.exit_json(**result)

        else:
            if module.check_mode is True:
                #module.exit_json(changed=True)
                result['changed'] = True
                result['vol_info']['pool_name'] = p.name()
                result['vol_info']['vol_path'] = "%s/%s" % (ET.fromstring(p.XMLDesc(0)).findtext('./target/path'), vol_name)
                result['vol_info']['vol_format'] = vol_format
                result['vol_info']['vol_capacity'] = vol_capacity
                module.exit_json(**result)
            else:
                pool_path = ET.fromstring(p.XMLDesc(0)).findtext('./target/path')

                volume = ET.fromstring("""<volume>
    <name>unknown</name>
    <capacity unit='bytes'>0</capacity>
    <target>
        <path>unknown</path>
        <format type='raw'/>
    </target>
    </volume>""")

                volume.find('./name').text = vol_name
                volume.find('./capacity').text = str(vol_capacity)
                volume.find('./target/path').text = '%s/%s' % (pool_path, vol_name)
                volume.find('./target/format').attrib['type'] = vol_format

                # hack(bl) use xml.dom.minidom in order to get str instead of bytes :(
                xml_buf = xml.dom.minidom.parseString(ET.tostring(volume))

                try:
                    res = p.createXML(xml_buf.toprettyxml(), 0)
                except libvirt.libvirtError as e:
                    module.fail_json(msg="Failed to create the storage volume: %s" % str(e))
                except:
                    msg_str = "Failed to create the storage volume: %s, %s" % (str(sys.exc_info()[0]), ET.tostring(volume))
                    module.fail_json(msg=msg_str)

                v = p.storageVolLookupByName(vol_name)
                result['changed'] = True
                result['vol_info']['pool_name'] = p.name()
                result['vol_info']['vol_path'] = v.path()
                result['vol_info']['vol_format'] = vol_format
                result['vol_info']['vol_capacity'] = v.info()[1]
                module.exit_json(**result)

    elif state =='absent':
        p = server.storagePoolLookupByName(pool_name)
        if vol_name in p.listVolumes():
            if module.check_mode is True:
                module.exit_json(changed=True)
            else:
                try:
                    p.storageVolLookupByName(vol_name).delete()
                except libvirt.libvirtError as e:
                    module.fail_json(msg="Failed to delete the storage volume: %s" % str(e))
                except:
                    module.fail_json(msg="Failed to delete the storage volume.")

                module.exit_json(changed=True)
        else:
            module.exit_json(changed=False)

    elif state =='wipe':
        if pool_name is None:
           module.fail_json(msg="You must specify a pool.")
        else:
            p = server.storagePoolLookupByName(pool_name)
            if vol_name in p.listVolumes():
                if module.check_mode is True:
                     module.exit_json(changed=True)
                else:
                     try:
                         p.storageVolLookupByName(vol_name).wipe()
                     except libvirt.libvirtError as e:
                         module.fail_json(msg="Failed to wipe the storage volume: %s" % str(e))
                     except:
                         module.fail_json(msg="Failed to wipe the storage volume.")

                     module.exit_json(changed=True)
            else:
                module.fail_json(msg="The volume was not found.")



from ansible.module_utils.basic import *

main()
