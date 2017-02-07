#!/bin/bash
##
## Installs the pre-requisites for running edX on a single Ubuntu 12.04
## instance.  This script is provided as a convenience and any of these
## steps could be executed manually.
##
## Note that this script requires that you have the ability to run
## commands as root via sudo.  Caveat Emptor!
##

##
## Sanity check
##
if [[ `lsb_release -rs` != "16.04" ]]; then
   echo "This script is only known to work on Ubuntu 16.04, exiting...";
   exit;
fi

##
## Set ppa repository source for gcc/g++ 4.8 in order to install insights properly
##
sudo apt-get install -y python-software-properties
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test

##
## Update and Upgrade apt packages
##
sudo apt-get update -y
sudo apt-get upgrade -y

##
## Install system pre-requisites
##
sudo apt-get install -y build-essential software-properties-common curl git-core libxml2-dev libxslt1-dev python-pip libmysqlclient-dev python-apt python-dev libxmlsec1-dev libfreetype6-dev swig gcc g++
sudo pip install --upgrade pip==8.1.2
sudo pip install --upgrade setuptools==24.0.3
sudo -H pip install --upgrade virtualenv==15.0.2

##
## Overridable version variables in the playbooks. Each can be overridden
## individually, or with $OPENEDX_RELEASE.
##
export OPENEDX_RELEASE="open-release/ficus.master"

 


if [ -n "$OPENEDX_RELEASE" ]; then
  EXTRA_VARS="-e edx_platform_version=$OPENEDX_RELEASE \
    -e certs_version=$OPENEDX_RELEASE \
    -e forum_version=$OPENEDX_RELEASE \
    -e xqueue_version=$OPENEDX_RELEASE \
    -e configuration_version=$OPENEDX_RELEASE \
    -e demo_version=$OPENEDX_RELEASE \
    -e NOTIFIER_VERSION=$OPENEDX_RELEASE \
    -e INSIGHTS_VERSION=$OPENEDX_RELEASE \
    -e ANALYTICS_API_VERSION=$OPENEDX_RELEASE \
    -e ECOMMERCE_VERSION=$OPENEDX_RELEASE \
    -e ECOMMERCE_WORKER_VERSION=$OPENEDX_RELEASE \
    -e PROGRAMS_VERSION=$OPENEDX_RELEASE \
  "
  CONFIG_VER=$OPENEDX_RELEASE
else
  CONFIG_VERt="master-str"
fi



##
## Clone the configuration repository and run Ansible
##
cd /var/tmp
git clone https://github.com/defStacker/configuration
cd configuration
git checkout $CONFIG_VER
git pull

##
## Install the ansible requirements
##
cd /var/tmp/configuration
sudo -H pip install -r requirements.txt

##
## Run the edx_sandbox.yml playbook in the configuration/playbooks directory
##
cd /var/tmp/configuration/playbooks 

sed -i 's/SANDBOX_ENABLE_ECOMMERCE: False/SANDBOX_ENABLE_ECOMMERCE: True/g' edx_sandbox.yml

sudo -E ansible-playbook -c local ./edx_sandbox.yml -i "localhost," $EXTRA_VARS
