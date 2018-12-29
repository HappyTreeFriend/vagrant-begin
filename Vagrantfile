# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Base configuration for the VM and provisioner
  config.vm.define "win2k8r2"
  config.vm.box = "autotestav_win2k8r2_virtualbox.box"
  config.vm.hostname = "autotestav-win2k8r2"
  config.vm.communicator = "winrm"
  config.winrm.retry_limit = 60
  config.winrm.retry_delay = 10

  config.vm.network "private_network", type: "dhcp"
  
  config.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct: true
  config.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", auto_correct: true

  config.vm.provision :shell, path: "scripts/configs/disable_firewall.bat"

  config.vm.provider :virtualbox do |v, override|
    v.gui = true
    v.customize ["modifyvm", :id, "--memory", 2048]
    v.customize ["modifyvm", :id, "--cpus", 2]
    v.customize ["setextradata", "global", "GUI/SuppressMessages", "all" ]
    v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
  end
end