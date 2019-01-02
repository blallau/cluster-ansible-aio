sudo ansible-playbook -i inventory/hosts playbooks/prerequisites.yml -vvv -e openshift_skip_deprecation_check=true


sudo ansible-playbook -i inventory/hosts playbooks/deploy_cluster.yml
