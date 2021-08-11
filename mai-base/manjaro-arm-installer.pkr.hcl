source "qemu" "example" {  
    iso_url           = "https://mirror.rackspace.com/archlinux/iso/2021.08.01/archlinux-2021.08.01-x86_64.iso"  
    iso_checksum      = "md5:cd9073fbdca8e85d2aad18aa8047ae77"  
    output_directory  = "output_manjaro-arm-installer"  
    shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"  
    disk_size         = "2G"  
    format            = "qcow2"  
    accelerator       = "kvm"  
    http_directory    = "http"  
    ssh_username      = "safe"  
    ssh_password      = "safe"  
    ssh_timeout       = "20m"  
    vm_name           = "manjaro-arm-installer"  
    net_device        = "virtio-net"  
    disk_interface    = "virtio"  
    boot_wait         = "10s"  
    boot_command      = ["<tab> text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/centos6-ks.cfg<enter><wait>"]
}

build {  sources = ["source.qemu.example"]}
