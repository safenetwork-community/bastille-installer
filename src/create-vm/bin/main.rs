use std::path::Path;
use std::process::Command;

use const_format::formatcp;

// command programs
const INSTALL: &str     = "install";
const MKDIR: &str       = "mkdir";
const PACKER: &str      = "packer";
const RM: &str          = "rm";
const SUDO: &str        = "sudo";

// arguments
const ARG_R: &str       = "-r";
const ARG_BUILD: &str       = "build";
const ARG_GROUP: &str       = "--group=libvirt-qemu";
const ARG_MODE_VMQ:  &str   =  "--mode=600";
const ARG_MODE_BL:  &str    =  "--mode=755";
const ARG_OWNER: &str       = "--owner=libvirt-qemu";

// VM names
const FORMAT_VM: &str   = "qcow2";
const HV_VM: &str       = "qemu";
const NAME_VM: &str     = "SE_bastille-installer-box";
const NAME_VMQ: &str    = formatcp!("{NAME_VM}.{FORMAT_VM}");
const OS_VM: &str       = "artixlinux";

// bootloader names
const NAME_KERNEL: &str = "bzImage";
const NAME_RAMFS: &str  = "initramfs-linux.img";
 
// Path names
const PATH_OUTPUT: &str             = formatcp!("./output");
const PATH_OUTPUT_QEMU: &str        = formatcp!("{PATH_OUTPUT}-{OS_VM}");
const PATH_LIBVIRT: &str            = "/var/lib/libvirt";
const PATH_VMQ_NEW: &str            = formatcp!("{PATH_LIBVIRT}/images");
const PATH_BOOTLOADERS_NEW: &str    = formatcp!("{PATH_LIBVIRT}/direct_kernel");

// File Locations
const LOC_KERNEL_OLD: &str  = formatcp!("{PATH_OUTPUT_QEMU}/{NAME_KERNEL}");
const LOC_RAMFS_OLD: &str   = formatcp!("{PATH_OUTPUT_QEMU}/{NAME_RAMFS}");
const LOC_VMQ_OLD: &str         = formatcp!("{PATH_OUTPUT_QEMU}/{NAME_VMQ}");
const LOC_TEMPLATE: &str        = formatcp!("{NAME_VM}.pkr.hcl");

// VM options 
const OPT_PACKER_ONLY: &str = formatcp!("-only={NAME_VM}.{HV_VM}.{OS_VM}");

// sh -c arguments
const INSTALL_VMQ: [&str; 6]    = [INSTALL, ARG_OWNER, ARG_GROUP, ARG_MODE_VMQ, LOC_VMQ_OLD, PATH_VMQ_NEW];
const INSTALL_KERNEL: [&str; 6] = [INSTALL, ARG_OWNER, ARG_GROUP, ARG_MODE_BL, LOC_KERNEL_OLD, PATH_BOOTLOADERS_NEW];
const INSTALL_RAMFS: [&str; 6]  = [INSTALL, ARG_OWNER, ARG_GROUP, ARG_MODE_BL, LOC_RAMFS_OLD, PATH_BOOTLOADERS_NEW];

fn main() {
   
    // delete OUTPUT folder if it exists
    if Path::new(&PATH_OUTPUT).exists() { 
        Command::new(RM)
        .arg(ARG_R)
        .arg(PATH_OUTPUT)
        .status()
        .unwrap_or_else(|e| panic!("mkdir fails\n{}", e));
    }

    // delete os OUTPUT folder if it exists
    if Path::new(&PATH_OUTPUT_QEMU).exists() { 
        Command::new(RM)
        .arg(ARG_R)
        .arg(PATH_OUTPUT_QEMU)
        .status()
        .unwrap_or_else(|e| panic!("mkdir fails\n{}", e));
    }
    
    // Run packer
    Command::new(PACKER)
    .arg(ARG_BUILD)
    .arg(OPT_PACKER_ONLY)
    .arg(LOC_TEMPLATE)
    .status()
    .unwrap_or_else(|e| panic!("packer failed to start\n{}", e));

    // Install the VM
    if Path::new(&PATH_OUTPUT_QEMU).exists() {
        if !Path::new(&PATH_LIBVIRT).exists() {
            Command::new(SUDO)
            .args([MKDIR, PATH_LIBVIRT])
            .status()
            .unwrap_or_else(|e| panic!("mkdir fails\n{}", e));
        }       

        Command::new(SUDO)
        .args(INSTALL_VMQ)
        .status()
        .unwrap_or_else(|e| panic!("installation to {PATH_VMQ_NEW} fails\n{}", e));
  
        if !Path::new(&PATH_BOOTLOADERS_NEW).exists() {
            Command::new(SUDO)
            .args([MKDIR, PATH_BOOTLOADERS_NEW])
            .status()
            .unwrap_or_else(|e| panic!("mkdir fails\n{}", e));
        }       

        Command::new(SUDO)
        .args(INSTALL_KERNEL)
        .status()
        .unwrap_or_else(|e| panic!("installation to {PATH_BOOTLOADERS_NEW} fails\n{}", e));
            
        Command::new(SUDO)
        .args(INSTALL_RAMFS)
        .status()
        .unwrap_or_else(|e| panic!("installation to {PATH_BOOTLOADERS_NEW} fails\n{}", e));

        Command::new(RM)
        .arg(ARG_R)
        .arg(PATH_OUTPUT_QEMU)
        .status()
        .unwrap_or_else(|e| panic!("Removing directory {PATH_OUTPUT_QEMU} fails\n{}", e));
    }
}
