use std::path::Path;
use std::process::{Command, exit};

use const_format::formatcp;

// command programs
const SUDO: &str = "sudo";

// arguments
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
const OPT_VI_DISK: &str     = formatcp!("{LOC_VMQ_NEW},format={VM_FORMAT}");
const OPT_VI_KERNEL: &str   = formatcp!("kernel={PATH_LV_DK}/bzImage,initrd={PATH_LV_DK}/initramfs.linux_amd64.cpio,\
        kernel_args=\"root=/dev/vda2 ro console=tty0 consolettyS0,115200n8d\"");

fn main() {
    // Start the VM
    if Path::new(&PATH_OUTPUT).exists() {
        match Command::new(SUDO)
            .arg(VIRT_INSTALL)
            .arg("--name").arg(VM_NAME)
            .arg("--vcpu").arg("2")
            .arg("--machine").arg("q35")
            .arg("--memory").arg("1024")
            .arg("--osinfo").arg("linux2022")
            .arg("--disk").arg(OPT_VI_DISK)
            .arg("--import").arg("--noautoconsole").arg("--boot")
            .arg(OPT_VI_KERNEL)
            .spawn()
            .unwrap_or_else(|_| panic!("virt-install failed to start"))
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
    }
}
