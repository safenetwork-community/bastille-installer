Vagrant.configure("2") do |config|
  config.vm.box = "safenetwork-community/manjaro-arm-installer"
  config.vm.define = "safenetwork-community_manjaro-arm-installer"
  config.vagrant.plugins = "vagrant-libvirt"

  config.vm.provider :libvirt do |lv|
    lv.title = "Manjaro-Arm-Installer"
    lv.description = "The safest way to install Manjaro OS on your SBC. Don't forget to add your SD card."
    lv.cpus = 1
    lv.memory = 512
    lv.usb_controller :model => "qemu-xhci"
  end

  config.vm.provision "shell", inline: <<-SHELL
     pacman --noconfirm -Syu
  SHELL
end
