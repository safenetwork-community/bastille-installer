Vagrant.configure("2") do |config|
  config.vm.box = "safenetwork-community/manjaro-arm-installer"
  config.vagrant.plugins = "vagrant-libvirt"

  config.vm.provider :libvirt do |lv|
    lv.cpus = 1
    lv.default_prefix = "manjaro-arm-installer"
    lv.description = "The safest way to install Manjaro OS on your SBC. Don't forget to add your SD card."
    lv.memory = 512
    lv.title = "Manjaro Arm Installer Box v0.4.0"
    lv.usb_controller :model => "qemu-xhci"
  end

  config.vm.provision "shell", inline: <<-SHELL
     pacman-mirrors --fasttrack 5
     pacman --noconfirm -Syu
   SHELL
end
