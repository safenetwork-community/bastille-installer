use std::path::Path;
use std::process::{Command, exit};

fn main() {

    // VM names
    let vm_name     = "SE_bastille-installer-box";
    let vm_hv       = "qemu";
    let vm_os       = "alpinelinux";
    let vm_format   = "qcow2";
    let vmq_name    = format!("{}.{}", vm_name, vm_format);
    
    // Path names
    let path_output         = format!("./output");
    let path_output_qemu    = format!("{}-{}", path_output, vm_os);
    let path_libvirt        = "/var/lib/libvirt";
    let path_lv_images      = format!("{}/images", path_libvirt);

    // File locations
    let loc_vmq_old        = format!("{}/{}", path_output_qemu, vmq_name);
    let loc_vmq_new        = format!("{}/{}", path_lv_images, vmq_name);
    let loc_template       = format!("{}.pkr.hcl", vm_name);

    // VM options 
    let opt_packer_only = format!("-only={}.{}.{}", vm_name, vm_hv, vm_os);

    // delete output folder if it exists
    if Path::new(&path_output).exists() { 
        match Command::new("rm")
            .arg("-r")
            .arg(path_output.clone())
            .spawn().unwrap()
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
    }

    // delete os output folder if it exists
    if Path::new(&path_output_qemu).exists() { 
        match Command::new("rm")
            .arg("-r")
            .arg(path_output_qemu)
            .spawn().unwrap()
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
    }

    // Run packer
    match Command::new("packer")
        .arg("build")
        .arg(opt_packer_only)
        .arg(loc_template)
        .spawn()
        .expect("packer failed to start")
        .wait() {
        Ok(_) => (),
        Err(_) => exit(1),
    }

    // Run the VM
    if Path::new(&path_output).exists() {
        match Command::new("sudo")
            .arg("chown")
            .arg("libvirt-qemu:libvirt-qemu")
            .arg(loc_vmq_old.clone())
            .spawn()
            .expect("chown to libvirt-qemu fails")
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
        
        match Command::new("sudo")
            .arg("chmod")
            .arg("600")
            .arg(loc_vmq_old.clone())
            .spawn()
            .expect("chmod to 600 fails")
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }

        match Command::new("sudo")
            .arg("mv")
            .arg(loc_vmq_old)
            .arg(loc_vmq_new)
            .spawn()
            .expect("moving qcow file fails")
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
    }
}
