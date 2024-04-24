use std::path::Path;
use std::process::{Command, exit};

use const_format::formatcp;

// command programs
const PACKER: &str = "packer";
const RM: &str = "rm";
const SUDO: &str = "sudo";

// arguments
const ARG_R: &str = "-r";
const BUILD: &str = "build";

// VM names
const VM_NAME: &str     = "SE_bastille-installer-box";
const VM_HV: &str       = "qemu";
const VM_OS: &str       = "artixlinux";
const VM_FORMAT: &str   = "qcow2";
const VMQ_NAME: &str    = formatcp!("{VM_NAME}.{VM_FORMAT}");
 
// Path names
const PATH_OUTPUT: &str         = formatcp!("./output");
const PATH_OUTPUT_QEMU: &str    = formatcp!("{PATH_OUTPUT}-{VM_OS}");
const PATH_LIBVIRT: &str        = "/var/lib/libvirt";
const PATH_LV_IMAGES: &str      = formatcp!("{PATH_LIBVIRT}/images");

// File LOCations
const LOC_VMQ_OLD: &str     = formatcp!("{PATH_OUTPUT_QEMU}/{VMQ_NAME}");
const LOC_VMQ_NEW: &str     = formatcp!("{PATH_LV_IMAGES}/{VMQ_NAME}");
const LOC_TEMPLATE: &str    = formatcp!("{VM_NAME}.pkr.hcl");

// VM options 
const OPT_PACKER_ONLY: &str = formatcp!("-only={VM_NAME}.{VM_HV}.{VM_OS}");

fn main() {
   
    // delete OUTPUT folder if it exists
    if Path::new(&PATH_OUTPUT).exists() { 
        match Command::new(RM)
            .arg(ARG_R)
            .arg(PATH_OUTPUT)
            .spawn().unwrap()
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
    }

    // delete os OUTPUT folder if it exists
    if Path::new(&PATH_OUTPUT_QEMU).exists() { 
        match Command::new(RM)
            .arg(ARG_R)
            .arg(PATH_OUTPUT_QEMU)
            .spawn().unwrap()
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
    }

    // Run packer
    match Command::new(PACKER)
        .arg(BUILD)
        .arg(OPT_PACKER_ONLY)
        .arg(LOC_TEMPLATE)
        .spawn()
        .expect("packer failed to start")
        .wait() {
        Ok(_) => (),
        Err(_) => exit(1),
    }

    // Run the VM
    if Path::new(&PATH_OUTPUT).exists() {
        match Command::new(SUDO)
            .arg("chown")
            .arg("libvirt-qemu:libvirt-qemu")
            .arg(LOC_VMQ_OLD)
            .spawn()
            .expect("chown to libvirt-qemu fails")
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
        
        match Command::new(SUDO)
            .arg("chmod")
            .arg("600")
            .arg(LOC_VMQ_OLD)
            .spawn()
            .expect("chmod to 600 fails")
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }

        match Command::new(SUDO)
            .arg("mv")
            .arg(LOC_VMQ_OLD)
            .arg(LOC_VMQ_NEW)
            .spawn()
            .expect("moving qcow file fails")
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
    }
}
