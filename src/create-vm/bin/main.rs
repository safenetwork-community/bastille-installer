use std::path::Path;
use std::process::{Command};

fn main() {

    // VM names
    let vm_name     = "SE_bastille-installer-box";
    let vm_hv       = "qemu";
    let vm_os       = "alpinelinux";
    let vm_format   = "qcow2";
    
    // File names
    let template = format!("{}.pkr.hcl", vm_name);

    // Path names
    let path_output         = format!("./output");
    let path_output_qemu    = format!("{}-{}", path_output, vm_os);
    let path_libvirt        = "/var/lib/libvirt";
    let path_lv_images      = format!("{}/images", path_libvirt);
    let path_lv_dk          = format!("{}/direct_kernel", path_libvirt);

    // VM options 
    let opt_packer_only = format!("-only={}.{}.{}", vm_name, vm_hv, vm_os);
    let opt_vi_disk     = format!("{}/{}.{},format={}", path_lv_images, vm_name, vm_format, vm_format);
    let opt_vi_kernel   = format!("kernel={}/bzImage,initrd={}/initramfs.linux_amd64.cpio,\
        kernel_args=\"root=/dev/vda2 ro console=tty0 consolettyS0,115200n8d\"", path_lv_dk, path_lv_dk);


    // delete output folder if it exists
    if Path::new(&path_output).exists() { 
        Command::new("rm")
            .arg("-r")
            .arg(path_output.clone())
            .spawn().unwrap();
    }

    // delete os output folder if it exists
    if Path::new(&path_output_qemu).exists() { 
        Command::new("rm")
            .arg("-r")
            .arg(path_output_qemu)
            .spawn().unwrap();
    }

    // Run packer
    Command::new("packer")
        .arg("build")
        .arg(opt_packer_only)
        .arg(template)
        .spawn()
        .expect("packer failed to start");

    // Run the VM
    if Path::new(&path_output).exists() { 
        Command::new("virt-install")
            .arg("--name").arg("SE_bastille_installer-box")
            .arg("--vcpu").arg("2")
            .arg("--machine").arg("q35")
            .arg("--memory").arg("1024")
            .arg("--osinfo").arg("alpinelinux3.18")
            .arg("--disk").arg(opt_vi_disk)
            .arg("--import").arg("--noautoconsole").arg("--boot")
            .arg(opt_vi_kernel)
            .spawn()
            .expect("virt-install failed to start");
    }
}
