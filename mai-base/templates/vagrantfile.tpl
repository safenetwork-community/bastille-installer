Vagrant.configure("2") do |config|
  config.vm.box = "safenetwork-community/safenetwork-community-installer"
  config.vagrant.plugins = "vagrant-libvirt"

  config.vm.provider :libvirt do |lv|
    lv.cpus = 1
    lv.default_prefix = "safenetwork-community-installer"
    lv.description = "The safest way to install the safenetwork app on a Arch Linux OS for your SBC. Don't forget to add your SD card."
    lv.memory = 512
    lv.title = "Safenetwork Community Installer Box v0.1.0"
    lv.usb_controller :model => "qemu-xhci"
  end

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 1
    vb.name = "Safenetwork Community Installer Box v0.1.0"
    vb.memory = 512
  end

  config.vm.provision "shell", inline: <<-SHELL
     pacman-mirrors --fasttrack 5
     pacman --noconfirm -Syu
   SHELL
end
