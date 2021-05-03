# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

VM_BOX_IMAGE = "ubuntu/bionic64"
VM_BOX_VERSION = "20200918.0.0"

Vagrant.configure("2") do |config|
  config.vm.box = VM_BOX_IMAGE
  config.vm.box_version = VM_BOX_VERSION
  config.vm.hostname = "dev.lo"
  config.vm.network :private_network, ip: "100.77.42.102"

  config.vm.provider :virtualbox do |v|
    v.name = "ubuntu-work"
    v.customize ["modifyvm", :id, "--memory", 4096]
    v.customize ["modifyvm", :id, "--cpus", 4]
    # Prevent VirtualBox from interfering with host audio stack
    v.customize ["modifyvm", :id, "--audio", "none"]

    disk_name = "box/disks/disk-1.vdb"
    unless File.exist?(disk_name)
        v.customize ["createhd", "--filename", disk_name, "--size", 102400 ]
    end

    v.customize [ "storageattach", :id, "--storagectl", "SCSI", "--port", 3, "--device", 0, "--type", "hdd", "--medium", disk_name ]
  end

  # before
  config.trigger.before :up do |trigger|
    trigger.info = "Prepare box folder"
    Dir.glob('./*.log').each { |file| FileUtils.rm_rf(file)}

    if (File.directory?('./box/puppet'))
      FileUtils.rm_rf('./box/puppet')
    end

    FileUtils.mkdir_p './box/puppet'
    FileUtils.copy_entry "./puppet-ctrl", "./box/puppet"
  end

  # Provision
  config.vm.synced_folder "./box/puppet", "/etc/puppetlabs/puppet/"
  config.vm.provision :shell, path: "./scripts/vagrant-bootstrap.sh"

  config.vm.provision "shell" do |s|
    ssh_prv_key = ""
    ssh_pub_key = ""
    if File.file?("#{Dir.home}/.ssh/id_rsa")
      ssh_prv_key = File.read("#{Dir.home}/.ssh/id_rsa")
      ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    else
      puts "No SSH key found. You will need to remedy this before pushing to the repository."
    end

    s.inline = <<-SHELL
      if grep -sq "#{ssh_pub_key}" /home/vagrant/.ssh/authorized_keys; then
        echo "SSH keys already provisioned."
        exit 0;
      fi
      echo "SSH key provisioning."
      mkdir -p /home/vagrant/.ssh/
      touch /home/vagrant/.ssh/authorized_keys
      echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
      echo #{ssh_pub_key} > /home/vagrant/.ssh/id_rsa.pub
      chmod 644 /home/vagrant/.ssh/id_rsa.pub
      echo "#{ssh_prv_key}" > /home/vagrant/.ssh/id_rsa
      chmod 600 /home/vagrant/.ssh/id_rsa
      chown -R vagrant:vagrant /home/vagrant
      exit 0
    SHELL
  end
end
