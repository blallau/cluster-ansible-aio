Bug Fix
-------
- Fix root login on Centos
- Fix bug when no network interface
- Fix Docker registry deployment on 18.04

Features
--------
- Manage static IP using a IP range not a CIDR
- Speedup deployment (async task, pipelining, strategy, disabling fact)
  https://shadow-soft.com/turbo-charge-your-ansible/
  https://acalustra.com/acelerate-your-ansible-playbooks-with-async-tasks.html
- Use block in some places to avoid 'when', 'with_item', 'sudo' statements repetition
  https://www.jeffgeerling.com/blog/new-features-ansible-20-blocks
