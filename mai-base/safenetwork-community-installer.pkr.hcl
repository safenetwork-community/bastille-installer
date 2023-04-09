variable "country" {
  type    = string
  default = "NL"

  validation {
      condition = length(var.country) == 2
      error_message = "The country value must be two characters long."
    }
}

variable "cpus" {
  type    = string
  default = "1"
}

variable "ram" {
  type    = string
  default = "1024"
}

variable "disk_size" {
  type    = string
  default = "4G"
}

variable "headless" {
  type    = bool
  default = false
  
  validation {
      condition = can(var.headless)
      error_message = "The headless value must exist."
    }
}

variable "kickstart_script" {
  type    = string
  default = "cfg-liveVM.sh"
}

variable "ssh_timeout" {
  type    = string
  default = "20m"

validation {
      condition = can(regex("[0-9]+[smh]", var.ssh_timeout))
      error_message = "The ssh_timeout value must be a number followed by the letter s(econds), m(inutes), or h(ours)."
    }
}

variable "write_zeros" {
  type    = string
  default = true

  validation {
      condition = can(var.write_zeros)
      error_message = "The write_zeros value must exist."
    }
}

variable "iso_release_date" {
  type    = string
  default = "2022.12.12"
  validation {
      condition = can(regex("(19|20)[0-9]{2}[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])", var.iso_release_date))
      error_message = "The iso_release_date value must be of yyyy.mm.dd or yyyy-mm-dd format."
  }
}

variable "ssh_username" {
  description = "Unpriviledged user to create."
  type = string
  default = "sci"
}

variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/id_sci"
}

locals {
  boot_command_qemu = [
                    "<enter><wait90s>",
                    "curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.kickstart_script} && chmod +x ${var.kickstart_script} && ./${var.kickstart_script} {{ .HTTPPort }}<enter>",
                  ]
  boot_command_virtualbox = [
                    "<enter><wait90s>",
                    "curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.kickstart_script} && chmod +x ${var.kickstart_script} && ./${var.kickstart_script} {{ .HTTPPort }}<enter>",
                  ]
  iso_checksum = "file:/var/lib/transmission/iso/archlinux-${var.iso_release_date}-x86_64.iso.sha256"
  iso_url      = "/var/lib/transmission/iso/archlinux-${var.iso_release_date}-x86_64.iso"
  name         = "safenetwork-community-installer"
  vm_name      = "safenetwork-community-installer"
}
source "qemu" "archlinux" {  
    accelerator            = "kvm"
    boot_command           = local.boot_command_qemu
    boot_wait              = "1s"
    cpus                   = var.cpus
    disk_compression       = true
    disk_image             = true
    disk_interface         = "virtio"
    disk_size              = var.disk_size
    firmware               = "/usr/share/edk2-ovmf/x64/OVMF.fd"
    format                 = "qcow2"
    headless               = var.headless
    http_directory         = "srv"
    iso_checksum           = local.iso_checksum
    iso_url                = local.iso_url
    machine_type           = "pc"
    memory                 = 4096
    net_device             = "virtio-net" 
    output_directory       = "output"
    qemu_binary            = "/usr/bin/qemu-system-x86_64"
    qemuargs               = [
      ["-monitor", "none"],
      ["-m", "${var.ram}M"], 
      ["-smp", "${var.cpus}"]
    ]
    shutdown_command       = "sudo systemctl poweroff"
    ssh_handshake_attempts  = 500 
    ssh_username           = var.ssh_username 
    ssh_private_key_file   = var.ssh_private_key_file
    ssh_port               = 22
    ssh_timeout            = var.ssh_timeout
    ssh_wait_timeout       = var.ssh_timeout
    vm_name                = "${local.vm_name}.qcow2"
    vnc_port_max           = 5910
    vnc_port_min           = 5910
}

build { 
  name = "safenetwork-community-installer"
  sources = ["source.qemu.archlinux"]

  provisioner "file" {
    destination = "/tmp/"
    source      = "./files"
  }

  provisioner "shell" {
    only = ["qemu.archlinux"]
    execute_command   = "{{ .Vars }} sudo -E bash '{{ .Path }}'"
    expect_disconnect = true
    script           = "scripts/setup.sh"
    pause_before = "10s"
  }

  post-processor "vagrant" {
    keep_input_artifact = true
    output = "output/${local.vm_name}_${source.type}_${source.name}-${formatdate("YYYY-MM", timestamp())}.box"
    vagrantfile_template = "templates/vagrantfile.tpl"
  }
}
