#!/bin/bash

echo "[PUPPET]: ===="
# https://docs.puppet.com/puppet/5.1/install_linux.html
# https://docs.puppet.com/puppet/5.1/puppet_platform.html
wget --no-verbose https://apt.puppetlabs.com/puppet6-release-xenial.deb
dpkg -i --force-confdef puppet6-release-xenial.deb
rm -f puppet6-release-xenial.deb

echo "[APT]: ===="
apt-get update
apt-get upgrade -y
apt-get install -y git puppet-agent r10k

echo "[PUPPET]: "
export PATH=/opt/puppetlabs/bin:$PATH
echo "Puppet version is $(puppet --version)"

echo "[SSH]: ===="
echo "[SSH]: Hosts"
ssh-keygen -R bitbucket.org
ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts
ssh-keygen -R github.com
ssh-keyscan github.com >> ~/.ssh/known_hosts

echo "[PUPPET]: ===="
echo "[PUPPET]: Running R10K"
cd /etc/puppetlabs/puppet
r10k deploy environment -p -v

echo "[PUPPET]: Running puppet"
# puppet apply /etc/puppetlabs/puppet/environments/production/manifests/site.pp --confdir=/etc/puppetlabs/puppet --environment=production --environmentpath=/etc/puppetlabs/puppet/environments/
