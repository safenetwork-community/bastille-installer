packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.9"
      source = "github.com/hashicorp/qemu"
    }
  }
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
    "<wait14s>root<enter>",
    "<wait3s>artix<enter>",
    "<wait3s>dinitctl enable sshd<enter>"
  ]
  boot_command_virtualbox = [
    "<down><down><enter>",
    "<wait14s>root<enter>",
    "<wait3s>artix<enter>",
    "<wait3s>dinitctl enable sshd<enter>"
  ]
  cpus              = 1
  disk_size         = "4G"
  efi_firmware_code = "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
  efi_firmware_vars = "/usr/share/edk2-ovmf/x64/OVMF_VARS.fd"
  headless          = "false"
  iso_checksum      = var.iso_checksum
  iso_url           = var.iso_url
  machine_type      = "q35"
  memory            = 4096
  ssh_password      = "artix"
  ssh_timeout       = "20m"
  ssh_username      = "artix"
  vm_name           = "bastille-installer"
  write_zeros       = "true"
}

source "qemu" "archlinux" {
  accelerator             = "kvm"
  boot_command            = local.boot_command_qemu
  boot_wait               = "15s"
  cpus                    = local.cpus
  disk_interface          = "virtio"
  disk_size               = local.disk_size
  efi_boot                = true
  efi_firmware_code       = local.efi_firmware_code
  efi_firmware_vars       = local.efi_firmware_vars
  format                  = "qcow2"
  headless                = local.headless
  iso_url                 = local.iso_url
  iso_checksum            = local.iso_checksum
  machine_type            = local.machine_type
  memory                  = local.memory
  net_device              = "virtio-net" 
  shutdown_command        = "sudo systemctl start poweroff.timer"
  ssh_handshake_attempts  = 500
  ssh_port                = 22
  ssh_password            = local.ssh_password
  ssh_timeout             = local.ssh_timeout
  ssh_username            = local.ssh_password
  ssh_wait_timeout        = local.ssh_timeout
  vm_name                 = "${local.vm_name}.qcow2"
}

build {
  name = "bastille-installer"
  sources = ["source.qemu.archlinux"]
  
  provisioner "file" {
    destination = "/tmp/"
    source      = "./files"
  }

  provisioner "shell" {
    only = ["qemu.archlinux"]
    execute_command = "{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
    "scripts/liveVM.sh",
    "scripts/tables.sh",
    "scripts/partitions.sh",
    "scripts/bootloader.sh",
    "scripts/setup.sh"
    ]
  }
      
  provisioner "shell" {
    execute_command = "{{ .Vars }} WRITE_ZEROS=${local.write_zeros} sudo -E -S bash '{{ .Path }}'"
    script = "scripts/cleanup.sh"
  }
    
  post-processor "vagrant" {
    output = "output/${local.vm_name}_${source.type}_${source.name}-${formatdate("YYYY-MM", timestamp())}.qcow2"
    vagrantfile_template = "templates/vagrantfile.tpl"
  }
}
