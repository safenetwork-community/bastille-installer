#!/usr/bin/env python

from pathlib import Path
import subprocess, os

vm_name = "SE_bastille-installer-box"
vm_hv = "qemu"
vm_os = "alpinelinux"
vm_ym = "2023-08"

command = "packer"
subcommand = "build"
option1 = f"-only={vm_name}.{vm_hv}.{vm_os}"

# Environment variables
packer_env = os.environ.copy()
packer_env["PACKER_LOG"] = "1"

# File names
template = f"{vm_name}.pkr.hcl"
vmq_name = f"{vm_name}.qcow2"
vmb_name = f"{vm_name}_{vm_hv}_{vm_os}_{vm_ym}.box"
gcf_name = "grub.cfg"
bfw_name = "libreboot.rom"

# Folder locations
path_home         = "/home/folaht"
path_output       = "./output"
path_output_qemu  = f"./output-{vm_os}"
path_virt_manager = "/var/lib/libvirt/images"
path_bibboot      = "./boot"
path_bootware     = f"{path_home}/Ehsaj/coreboot"
path_cb_build     = f"{path_bootware}/build"
path_virt_boot    = "/var/lib/libvirt/boot"

# File locations
location_vmq_old = f"{path_output_qemu}/{vmq_name}"
location_vmq_new = f"{path_virt_manager}/{vmq_name}"
location_gcf_old = f"{path_bibboot}/{gcf_name}"
location_gcf_new = f"{path_bootware}/{gcf_name}"
location_bfw_old = f"{path_cb_build}/{bfw_name}"
location_bfw_new = f"{path_virt_boot}/{bfw_name}"

# delete output folder if it exists
if Path(path_output).is_dir(): 
    subprocess.run(["rm", "-r", path_output])

# delete os output folder if it exists
if Path(path_output_qemu).is_dir(): 
    subprocess.run(["rm", "-r", path_output_qemu])

# Run packer
args = [command, subcommand, option1, template]
print(' '.join(args)) 
subprocess.run(args, env=packer_env)

# Move box to virt-manager 
if Path(path_output).exists() and Path(path_output).is_dir():  
    #subprocess.run(["sudo", "mv", location_gcf_old, location_gcf_new])
    #with open("librebootgrub.log", "w") as outfile:
    #    subprocess.run(["nice", "make", "-C", "~/Ehsaj/lbmk", "-j5"], stdout=outfile) 
    subprocess.run(["sudo", "chown", "libvirt-qemu:libvirt-qemu", location_vmq_old])
    subprocess.run(["sudo", "chmod", "600", location_vmq_old])
    subprocess.run(["sudo", "mv", location_vmq_old, location_vmq_new])
    #subprocess.run(["sudo", "chown", "libvirt-qemu:libvirt-qemu", location_bfw_old])
    #subprocess.run(["sudo", "mv", location_bfw_old, location_bfw_new])
    subprocess.run(["sudo", "virt-install",
                    "--name", "bastille-installer",
                    "--vcpu", "2",
                    "--memory", "1024",
                    "--osinfo", "alpinelinux3.18",
                    "--disk", location_vmq_new, 
                    "--import",
                    "--boot", f"loader={location_bfw_new}"])
