Vagrant.configure("2") do |config|
  config.vm.box = "safenetwork-community/bastille-installer"
  config.vagrant.plugins = "vagrant-libvirt"

  config.vm.provider :libvirt do |lv|
    lv.cpus = 1
    lv.cpu_mode = "host-passthrough" 
    lv.default_prefix = "bastille-installer"
    lv.description = "The safest way to install the safenetwork app on a Manjaro Linux OS for your SBC. Don't forget to add your SD card."
    lv.driver = "kvm"
    lv.loader = "/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd"
    lv.machine_type = "q35"
    lv.memory = 4096
    lv.format = "qemu"
    lv.title = "Bastille Flasher v0.5.0"
    lv.usb_controller :model => "qemu-xhci"
  end

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 1
    vb.name = "Bastille Flasher v0.5.0"
    vb.memory = 4096
  end

  config.vm.provision "shell", inline: <<-SHELL
     pacman-mirrors --fasttrack 5
     pacman --noconfirm -Syu
   SHELL
end
