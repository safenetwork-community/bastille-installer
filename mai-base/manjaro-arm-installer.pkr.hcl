variable "country" {
  type    = string
  default = "NL"
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
  iso_checksum     = "sha1:a981ef7ff846f373809dad59b26e325dff3ef4b8"
  iso_url          = "https://download.manjaro.org/xfce/21.1.1/manjaro-xfce-21.1.1-minimal-210827-linux54.iso"
  name             = "manjaro-arm-installer"
  vm_name          = "manjaro-arm-installer" 
}

source "qemu" "main" {  
    accelerator            = "kvm"  
    boot_command           = [
                            "<enter><wait30><wait30>",
                            "<leftCtrlOn><leftAltOn><f2><leftCtrlOff><leftAltOff><wait10>",
                            "manjaro<enter><wait2>",
                            "manjaro<enter><wait2>",
                            "su -<enter><wait3>",
                            "manjaro<enter><wait2>",
                            "/usr/bin/curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/enable-ssh.sh<enter><wait3>",
                            "/usr/bin/curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/poweroff.timer<enter><wait3>",
                            "/usr/bin/bash ./enable-ssh.sh<enter><wait15>",
                           ]
    boot_wait              = "2s"  
    communicator           = "ssh"
    cpus                   = 1
    disk_interface         = "virtio"  
    disk_size              = 4096
    format                 = "qcow2"  
    headless               = "${var.headless}"
    http_directory         = "srv"  
    iso_checksum           = "${local.iso_checksum}"
    iso_url                = "${local.iso_url}"
    memory                 = 2048
    net_device             = "virtio-net"  
    output_directory       = "output"    
    shutdown_command       = "sudo systemctl start poweroff.timer"
    ssh_username           = "vagrant"  
    ssh_password           = "vagrant"
    ssh_port               = 22
    ssh_timeout            = "${var.ssh_timeout}"
    vm_name                = "${local.vm_name}.qcow2"
    vnc_port_max           = 5910
    vnc_port_min           = 5910
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
