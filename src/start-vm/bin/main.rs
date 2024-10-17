use std::path::Path;
use std::process::Command;

use const_format::formatcp;

// command programs
const SUDO: &str = "sudo";

// arguments
const OS: &str = "archlinux";
const VIRT_INSTALL: &str = "virt-install";

// VM names
const VM_NAME: &str     = "SE_bastille-installer-box";
const VM_FORMAT: &str   = "qcow2";
const VMQ_NAME: &str    = formatcp!("{VM_NAME}.{VM_FORMAT}");
 
// Path names
const PATH_OUTPUT: &str     = "./output";
const PATH_LIBVIRT: &str    = "/var/lib/libvirt";
const PATH_LV_IMAGES: &str  = formatcp!("{PATH_LIBVIRT}/images");
const PATH_LV_DK: &str      = formatcp!("{PATH_LIBVIRT}/direct_kernel");

// File Locations
const LOC_VMQ_NEW: &str     = formatcp!("{PATH_LV_IMAGES}/{VMQ_NAME}");

// VM options 
const SIZE_VM: u32          = 5; 
const OPT_VI_DISK: &str     = formatcp!("{LOC_VMQ_NEW},format={VM_FORMAT},size={SIZE_VM}");
const OPT_VI_KERNEL: &str   = formatcp!("kernel={PATH_LV_DK}/bzImage,initrd={PATH_LV_DK}/initramfs-linux.img,\
        kernel_args=\"root=/dev/vda2 rw console=tty0 consolettyS0,115200n8d\"");

fn main() {
    // Start the VM
    if Path::new(&PATH_OUTPUT).exists() {
        Command::new(SUDO)
        .arg(VIRT_INSTALL)
        .arg("--name").arg(VM_NAME)
        .arg("--vcpu").arg("2")
        .arg("--machine").arg("q35")
        .arg("--memory").arg("1024")
        .arg("--network").arg("network=default,model=virtio-net,mac=52:54:00:53:b1:b0")
        .arg("--osinfo").arg(OS)
        .arg("--disk").arg(OPT_VI_DISK)
        .arg("--import").arg("--noautoconsole").arg("--boot")
        .arg(OPT_VI_KERNEL)
        .status()
        .unwrap_or_else(|e| panic!("virt-install failed to start\n{}", e));
    }
}
