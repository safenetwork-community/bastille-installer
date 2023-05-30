packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.9"
      source = "github.com/hashicorp/qemu"
    }
  }
}

variable "country" {
  type = string
  default = "NL"
}

variable "iso_checksum" {
  type = string
  default = "file:https://download.artixlinux.org/weekly-iso/shasums256"
}

variable "iso_url" {
  type = string
  default = "https://download.artixlinux.org/weekly-iso/artix-base-dinit-YYYYMMDD-x86_64.iso"
}

locals {
  boot_command_qemu = [
    "<down><down><enter>",
    "<wait15s>root<enter>",
    "<wait10s>artix<enter>",
    "<wait3s>curl -Os http://{{ .HTTPIP }}:{{ .HTTPPort }}/${local.init_script} && chmod +x ./${local.init_script} && ./${local.init_script} {{ .HTTPPort }}<enter>"
  ]
  boot_command_virtualbox = [
    "<down><down><enter>",
    "<wait15s>root<enter>",
    "<wait10s>artix<enter>",
    "<wait3s>/tmp/files/initLiveVM.sh<enter>"
  ]
  cpus                  = 1
  disk_size             = "4G"
  efi_firmware_code     = "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
  efi_firmware_vars     = "/usr/share/edk2-ovmf/x64/OVMF_VARS.fd"
  headless              = "false"
  http_directory        = "srv" 
  init_script           = "initLiveVM.sh"
  iso_checksum          = var.iso_checksum
  iso_url               = var.iso_url
  machine_type          = "q35"
  memory                = 4096
  ssh_private_key_file  = "~/.ssh/id_bas"
  ssh_timeout           = "20m"
  ssh_username          = "bas"
  vm_name               = "bastille-installer"
}

source "qemu" "artix" {
  accelerator             = "kvm"
  boot_command            = local.boot_command_qemu
  boot_wait               = "25s"
  cpus                    = local.cpus
  disk_interface          = "virtio"
  disk_size               = local.disk_size
  efi_boot                = true
  efi_firmware_code       = local.efi_firmware_code
  efi_firmware_vars       = local.efi_firmware_vars
  format                  = "qcow2"
  headless                = local.headless
  http_directory          = local.http_directory
  iso_url                 = local.iso_url
  iso_checksum            = local.iso_checksum
  machine_type            = local.machine_type
  memory                  = local.memory
  net_device              = "virtio-net" 
  shutdown_command        = ""
  shutdown_timeout        = "5m"
  ssh_handshake_attempts  = 500
  ssh_port                = 22
  ssh_private_key_file    = local.ssh_private_key_file
  ssh_timeout             = local.ssh_timeout
  ssh_username            = local.ssh_username
  ssh_wait_timeout        = local.ssh_timeout
  vm_name                 = "${local.vm_name}.qcow2"
}

build {
  name = "bastille-installer"
  sources = ["source.qemu.artix"]
  
  provisioner "file" {
    destination = "/tmp/"
    source      = "./files"
  }

  provisioner "shell" {
    only = ["qemu.artix"]
    execute_command = "echo 'primany provisioner';{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    pause_after = "10s"
    pause_before = "10s"
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
      
  provisioner "shell" {
    execute_command = "echo 'secondary provisioner';{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    pause_before = "10s"
    scripts = [
      "scripts/services.sh",
      "scripts/cleanup.sh"
    ]
  }
    
  post-processor "vagrant" {
    output = "output/${local.vm_name}_${source.type}_${source.name}-${formatdate("YYYY-MM", timestamp())}.qcow2"
    vagrantfile_template = "templates/vagrantfile.tpl"
  }
}
