# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

VM_BOX_IMAGE = "ubuntu/bionic64"
VM_BOX_VERSION = "20200311.0.0"

Vagrant.configure("2") do |config|
  config.vm.box = VM_BOX_IMAGE
  config.vm.box_version = VM_BOX_VERSION
  config.vm.hostname = "dev.lo"

  config.vm.provider :virtualbox do |v|
    v.name = "ubuntu-work"
    v.customize ["modifyvm", :id, "--memory", 4096]
    v.customize ["modifyvm", :id, "--cpus", 4]
    # Prevent VirtualBox from interfering with host audio stack
    v.customize ["modifyvm", :id, "--audio", "none"]
  end

  config.ssh.forward_agent = true

  config.vm.provision :shell do |shell|
    shell.inline = "touch $1 && chmod 0440 $1 && echo $2 > $1"
    shell.args = %q{/etc/sudoers.d/root_ssh_agent "Defaults env_keep += \"SSH_AUTH_SOCK\""}
  end

  # before
  config.trigger.before :up do |trigger|
    trigger.info = "Prepare box folder"
    trigger.ignore = [:destroy, :halt]
    FileUtils.rm_rf('./box/puppet')
    FileUtils.mkdir_p('./box/puppet/environments/production')
    Dir.glob('./*.log').each { |file| FileUtils.rm_rf(file)}

    FileUtils.copy_entry "./puppet-ctrl", "./box/puppet"
    FileUtils.copy_entry "./hieradata", "./box/puppet/environments/production/hieradata"
    FileUtils.copy_entry "./manifests", "./box/puppet/environments/production/manifests"
    FileUtils.copy_entry "./site", "./box/puppet/environments/production/site"
    FileUtils.cp "./environment.conf", "./box/puppet/environments/production/environment.conf"
    FileUtils.cp "./Puppetfile", "./box/puppet/environments/production/Puppetfile"
  end

  # Provision
  config.vm.synced_folder "./box/puppet", "/etc/puppetlabs/puppet/"
  config.vm.provision :shell, path: "./scripts/vagrant-bootstrap.sh"
end
