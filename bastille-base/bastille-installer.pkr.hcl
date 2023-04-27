variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/id_bas"
}

variable "ssh_timeout" {
  type    = string
  default = "20m"

  validation {
      condition = can(regex("[0-9]+[smh]", var.ssh_timeout))
      error_message = "The ssh_timeout value must be a number followed by the letter s(econds), m(inutes), or h(ours)."
    }
}

variable "ssh_username" {
  description = "Unpriviledged user to create."
  type = string
  default = "bas"
}

locals {
  boot_command_qemu = [
    "<wait5><enter><wait90s>",
    "curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/${local.kickstart_script} && chmod +x ${local.kickstart_script} && ./${local.kickstart_script} {{ .HTTPPort }}<enter>",
  ]
  boot_command_virtualbox = [
    "<enter><wait90s>",
    "curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/${local.kickstart_script} && chmod +x ${local.kickstart_script} && ./${local.kickstart_script} {{ .HTTPPort }}<enter>",
  ]
  cpus              = 1
  disk_size         = "4G"
  firmware          = "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
  headless          = "false"
  iso_checksum      = "file:https://mirrors.edge.kernel.org/archlinux/iso/{{isotime \"2006.01\"}}.01/sha256sums.txt"
  iso_url           = "https://mirrors.edge.kernel.org/archlinux/iso/{{isotime \"2006.01\"}}.01/archlinux-{{isotime \"2006.01\"}}.01-x86_64.iso"
  kickstart_script  = "cfg_liveVM.sh"
  machine_type      = "q35"
  memory            = 4096
  http_directory    = "srv"
  vm_name           = "bastille-installer"
  write_zeros       = "true"
}

source "qemu" "archlinux" {
  accelerator             = "kvm"
  boot_command            = local.boot_command_qemu
  boot_wait               = "1s"
  cpus                    = local.cpus
  disk_interface         = "virtio"
  disk_size               = local.disk_size
  firmware                = local.firmware
  format                  = "qcow2"
  headless                = local.headless
  http_directory          = local.http_directory
  iso_url                 = local.iso_url
  iso_checksum            = local.iso_checksum
  machine_type            = local.machine_type
  memory                  = local.memory
  net_device             = "virtio-net" 
  qemuargs               = [
      ["-m", "${local.memory}M"],
      ["-monitor", "none"],
      ["-smp", "${local.cpus}"]
    ]
  shutdown_command        = "sudo systemctl start poweroff.timer"
  ssh_handshake_attempts  = 500
  ssh_port                = 22
  ssh_private_key_file    = var.ssh_private_key_file
  ssh_timeout             = var.ssh_timeout
  ssh_username            = var.ssh_username
  ssh_wait_timeout        = var.ssh_timeout
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
    "scripts/configure-qemu.sh",
    "scripts/configure-shared.sh",
    "scripts/partition-table-gpt.sh",
    "scripts/partition-ext4-efi.sh",
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
