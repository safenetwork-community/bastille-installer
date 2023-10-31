use std::path::Path;
use std::process::{Command, exit};

fn main() {

    // VM names
    let vm_name     = "SE_bastille-installer-box";
    let vm_format   = "qcow2";
    let vmq_name    = format!("{}.{}", vm_name, vm_format);
    
    // Path names
    let path_output         = format!("./output");
    let path_libvirt        = "/var/lib/libvirt";
    let path_lv_images      = format!("{}/images", path_libvirt);
    let path_lv_dk          = format!("{}/direct_kernel", path_libvirt);

    // File locations
    let loc_vmq_new        = format!("{}/{}", path_lv_images, vmq_name);

    // VM options 
    let opt_vi_disk     = format!("{},format={}", loc_vmq_new, vm_format);
    let opt_vi_kernel   = format!("kernel={}/bzImage,initrd={}/initramfs.linux_amd64.cpio,\
        kernel_args=\"root=/dev/vda2 ro console=tty0 consolettyS0,115200n8d\"", path_lv_dk, path_lv_dk);

    // Start the VM
    if Path::new(&path_output).exists() {
        match Command::new("sudo")
            .arg("virt-install")
            .arg("--name").arg(vm_name)
            .arg("--vcpu").arg("2")
            .arg("--machine").arg("q35")
            .arg("--memory").arg("1024")
            .arg("--osinfo").arg("alpinelinux3.18")
            .arg("--disk").arg(opt_vi_disk)
            .arg("--import").arg("--noautoconsole").arg("--boot")
            .arg(opt_vi_kernel)
            .spawn()
            .expect("virt-install failed to start")
            .wait() {
            Ok(_) => (),
            Err(_) => exit(1),
        }
    }
}
