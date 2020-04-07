#!/bin/bash

echo "[APT]: Update"
apt-get update
apt-get upgrade -y

echo "[DPKG]: Checking for: puppet6-release"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' puppet6-release|grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
    echo "Installing puppet6-release"
    wget --no-verbose https://apt.puppetlabs.com/puppet6-release-xenial.deb
    dpkg -i --force-confdef puppet6-release-xenial.deb
    rm -f puppet6-release-xenial.deb
fi

if [ ! -L "/usr/bin/puppet" ] || [ ! -e "/usr/bin/puppet" ]; then
    ln -s /opt/puppetlabs/bin/puppet /usr/bin/puppet
fi

echo "Checking for: puppet-agent"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' puppet-agent|grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
    echo "Installing puppet-agent"
    apt-get install -y puppet-agent
fi

echo "Checking for: git"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' puppet-agent|grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
    echo "Installing git"
    apt-get install -y git
fi

echo "Checking for: r10k"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' puppet-agent|grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
    echo "Installing r10k"
    apt-get install -y r10k
fi

export PATH=/opt/puppetlabs/bin:$PATH
echo "[PUPPET]: version is $(puppet --version)"

echo "[PUPPET]: Control Repo"
git clone https://github.com/OxCom/puppet-php-skeleton-dev.git
cp -rf ./puppet-php-skeleton-dev/* /etc/puppetlabs/puppet/
rm -rf ./puppet-php-skeleton-dev

echo "[PUPPET]: Running R10K"
cd /etc/puppetlabs/puppet
r10k deploy environment -p -v

echo "[PUPPET]: Running puppet"
puppet apply --verbose /etc/puppetlabs/puppet/environments/production/manifests/site.pp --confdir=/etc/puppetlabs/puppet --environment=production --environmentpath=/etc/puppetlabs/puppet/environments/
