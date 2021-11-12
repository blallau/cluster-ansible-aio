#!/bin/bash

#set -x
set -e

echo centos > ~/.cluster-ansible-aio-env

OS='centos'

############ DO NOT MOVE ###############
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_params.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh
############ DO NOT MOVE ###############

RETRIEVE_ARTIFACTS=true

retrieveArtifacts
retrieveDataArtifacts
