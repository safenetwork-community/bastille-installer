packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

locals {
  boot_command_qemu = [
    "root<enter>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait5s>",
    "wget -qO- http://{{ .HTTPIP }}:{{ .HTTPPort }}/${local.init_script} | LOCAL_PORT={{ .HTTPPort }} ash<enter>",
  ]
  cpus                  = 1
  disk_size             = "4G"
  disk_size_vb          = "4000"
  format                = "qcow2"
  headless              = "true"
  http_directory        = "srv"
  init_script           = "initLiveVM.sh"
  iso_checksum          = "sha256:6bc7ff54f5249bfb67082e1cf261aaa6f307d05f64089d3909e18b2b0481467f"
  iso_url               = "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-virt-3.18.2-x86_64.iso"
  machine_type          = "q35"
  memory                = 4096
  ssh_private_key_file  = "~/.ssh/id_bas"
  ssh_timeout           = "20m"
  ssh_username          = "bas"
  vm_name               = "SE_bastille-installer-box"
}

source "qemu" "alpinelinux" {
  accelerator             = "kvm"
  boot_command            = local.boot_command_qemu
  boot_wait               = "40s"
  cpus                    = local.cpus
  disk_interface          = "virtio-scsi"
  disk_size               = local.disk_size
  efi_boot                = false
  format                  = "qcow2"
  headless                = local.headless
  http_directory          = local.http_directory
  iso_checksum            = local.iso_checksum
  iso_url                 = local.iso_url
  machine_type            = local.machine_type
  memory                  = local.memory
  net_device              = "virtio-net" 
  shutdown_command        = "doas poweroff"
  ssh_handshake_attempts  = 500
  ssh_port                = 22
  ssh_private_key_file    = local.ssh_private_key_file
  ssh_timeout             = local.ssh_timeout
  ssh_username            = local.ssh_username
  ssh_wait_timeout        = local.ssh_timeout
  vm_name                 = "${local.vm_name}.qcow2"
  vtpm                    = true
}

build {
  name = "SE_bastille-installer-box"
  sources = ["source.qemu.alpinelinux"]
  
  provisioner "file" {
    destination = "/tmp"
    source      = "./files/rootdir"
  }

  provisioner "shell" {
    execute_command = "doas '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
      "scripts/provision.sh",
      "scripts/bootloader.sh",
      "scripts/cleanup.sh"
    ]
  }
  
  provisioner "file" {
    destination = "~"
    source      = "./files/user/"
  }
 
  provisioner "file" {
    destination = "./boot/vmlinuz-virt"
    direction   = "download" 
    source      = "/boot/vmlinuz-virt"
  } 

  provisioner "file" {
    destination = "./tmp/initramfs-virt"
    direction   = "download" 
    source      = "/tmp/initramfs-virt"
  } 

  provisioner "file" {
    destination = "./boot/initramfs-virt.gz"
    direction   = "download" 
    source      = "/tmp/initramfs-virt.gz"
  } 

  post-processor "vagrant" {
    keep_input_artifact = true
    output = "output/${local.vm_name}-${formatdate("YYYY-MM", timestamp())}.box"
    vagrantfile_template = "templates/vagrantfile.tpl"
  }
}
