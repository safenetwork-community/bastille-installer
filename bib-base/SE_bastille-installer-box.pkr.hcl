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
    "<down><down><enter>",
    "<wait15s>root<enter>",
    "<wait5s>artix<wait7s><enter><wait3s>",
    "LOCAL_PORT={{ .HTTPPort }} bash <(curl -s http://{{ .HTTPIP }}:{{ .HTTPPort }}/${local.init_script})<enter>", 
  ]
  cpus                  = 1
  disk_size             = "5G"
  disk_size_vb          = "4000"
  format                = "qcow2"
  headless              = "false"
  http_directory        = "srv"
  init_script           = "initLiveVM.sh"
  iso_checksum          = "sha256:3dd4f42741ea8fb7fd1d3713fbba7706a0250429d0a61eb16d93654a75a7ac2d"
  iso_url               = "https://download.artixlinux.org/iso/artix-base-dinit-20230814-x86_64.iso"
  machine_type          = "q35"
  memory                = 4096
  ssh_private_key_file  = "~/.ssh/id_bas"
  ssh_timeout           = "20m"
  ssh_username          = "bas"
  vm_name               = "SE_bastille-installer-box"
  write_zeros           = "true"
}

source "qemu" "artixlinux" {
  accelerator             = "kvm"
  boot_command            = local.boot_command_qemu
  boot_wait               = "2s"
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
  shutdown_command        = "sudo poweroff"
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
  sources = ["source.qemu.artixlinux"]
  
  provisioner "file" {
    destination = "/tmp"
    source      = "./files/rootdir"
  }

  provisioner "shell" {
    execute_command = "sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
      "scripts/liveVM.sh",
      "scripts/tables.sh",
      "scripts/partitions.sh",
      "scripts/base.sh",
      "scripts/bootloader.sh",
      "scripts/pacman.sh",
      "scripts/setup.sh"
    ]
  }
  
  provisioner "file" {
    destination = "./output-artixlinux/initramfs-linux.img"
    direction   = "download"
    source      = "/boot/initramfs-linux.img"
  }
  
  provisioner "file" {
    destination = "./output-artixlinux/bzImage"
    direction   = "download"
    source      = "/boot/vmlinuz-linux"
  }
 
  provisioner "shell" {
    execute_command = "{{ .Vars }} WRITE_ZEROS=${local.write_zeros} sudo -E -S bash '{{ .Path }}'"
    script = "scripts/cleanup.sh"
  }

  provisioner "file" {
    destination = "~"
    source      = "./files/userdir/"
  }
 
  post-processor "vagrant" {
    keep_input_artifact = true
    output = "output/${local.vm_name}-${formatdate("YYYY-MM", timestamp())}.box"
    vagrantfile_template = "templates/vagrantfile.tpl"
  }
}
