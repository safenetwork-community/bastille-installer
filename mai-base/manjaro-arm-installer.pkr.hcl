variable "country" {
  type    = string
  default = "US"
}

variable "headless" {
  type    = string
  default = "false"
}

variable "ssh_timeout" {
  type    = string
  default = "20m"
}

variable "write_zeros" {
  type    = string
  default = "true"
}

locals {
  iso_checksum_url = "https://mirrors.kernel.org/archlinux/iso/${formatdate("YYYY.MM", timestamp())}.01/sha1sums.txt"
  iso_url          = "https://mirrors.kernel.org/archlinux/iso/${formatdate("YYYY.MM", timestamp())}.01/archlinux-${formatdate("YYYY.MM", timestamp())}.01-x86_64.iso"
  name             = "manjaro-arm-installer"
  vm_name          = "manjaro-arm-installer" 
}

source "qemu" "main" {  
    accelerator            = "kvm"  
    boot_command           = [
                            "<enter><wait15><wait15><wait15><wait15><wait15>",
                            "/usr/bin/curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/enable-ssh.sh<enter><wait5>",
                            "/usr/bin/curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/poweroff.timer<enter><wait5>",
                            "/usr/bin/bash ./enable-ssh.sh<enter><wait5>",
                           ]
    boot_wait              = "5s"  
    cpus                    = 1
    disk_interface         = "virtio"  
    disk_size              = 4096  
    format                 = "qcow2"  
    headless               = "${var.headless}"
    http_directory         = "srv"  
    iso_checksum           = "file:${local.iso_checksum_url}"
    iso_url                = "${local.iso_url}"
    memory                 = 768
    net_device             = "virtio-net"  
    output_directory       = "output"    
    ssh_username           = "vagrant"  
    ssh_password           = "vagrant"  
    ssh_timeout            = "${var.ssh_timeout}"
    shutdown_command       = ""
    vm_name                = "${local.vm_name}"  
}

build { 
  name = "manjaro-arm-installer"
  sources = ["source.qemu.main"]

  provisioner "shell" {
    execute_command   = "{{ .Vars }} COUNTRY=${var.country} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    script            = "scripts/install-base.sh"
  }

  provisioner "shell" {
    execute_command = "{{ .Vars }} WRITE_ZEROS=${var.write_zeros} sudo -E -S bash '{{ .Path }}'"
    script          = "scripts/cleanup.sh"
  }

  post-processor "vagrant" { 
      keep_input_artifact = true
      output = "output/${local.vm_name}_${source.type}_${source.name}-${formatdate("YYYY-MM", timestamp())}.box"
  }
}
