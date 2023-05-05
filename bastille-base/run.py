#!/usr/bin/env python

from pathlib import Path
import subprocess
import urllib.request
from html.parser import HTMLParser



class IsoParse(HTMLParser):

    def __init__(self):
        super().__init__()
        self.reset()
        self.iso_url = f"{isoURL}/{artix_flavour}-YYYYMMDD-x86_64.iso"

    def handle_starttag(self, tag, attrs):
        if tag == "a":  
            for name, link in attrs:
                if link and name == "href" and link.startswith(f"{isoURL}/{artix_flavour}") == True:
                    self.iso_url = link
                    break

def findIsoURL():
    #Import HTML from a URL
    url = urllib.request.urlopen(f"{isoURL}s.php")
    html = url.read().decode()
    url.close()

    p = IsoParse()
    p.feed(html)
    return p.iso_url

def findChecksum():
    url = urllib.request.urlopen(f"{isoURL}/sha256sums")
    for line in url:
        if line.__contains__(artix_flavour.encode()):  
            return line.split()[0].decode("utf-8")


command = "packer"
subcommand = "build"

# URLs
isoURL = "https://download.artixlinux.org/weekly-iso"
artix_flavour = "artix-base-dinit"

# File names
template = "bastille-installer.pkr.hcl"
vm_name = "bastille-installer_qemu_archlinux-2023-04.qcow2"

# Folder locations
path_output = "./output"
path_virt_manager = "/var/lib/libvirt/images/"

# File locations
location_vm_old = f"{path_output}/{vm_name}"
location_vm_new = f"{path_virt_manager}/{vm_name}"

# delete output folder if it exists
if Path(path_output).is_dir(): 
    subprocess.run(["rm", "-r", "output"])

if __name__ == '__main__':

    iso_url = findIsoURL()
    iso_checksum = findChecksum()
    
    # Run packer
    print([command, subcommand, 
           "-var", f"iso_url={iso_url}",
           "-var", f"iso_checksum={iso_checksum}", 
           template])
    subprocess.run([command, subcommand, 
                    "-var", f"iso_url={iso_url}", 
                    "-var", f"iso_checksum={iso_checksum}", 
                    template])

    # Copy to virt-manager default images folder
    if Path(path_output).exists() and Path(path_output).is_dir():  
        subprocess.run(["sudo", "chown", "libvirt-qemu:libvirt-qemu", location_vm_old])
        subprocess.run(["sudo", "chmod", "600", location_vm_old])
        subprocess.run(["sudo", "mv", location_vm_old, location_vm_new])
        #subprocess.run(["sudo", "virt-install",
        #                "--name", "bastille-installer",
        #                "--vcpu", "2",
        #                "--memory", "1024",
        #                "--osinfo", "archlinux",
        #                "--disk", location_vm_new, 
        #                "--import",
        #                "--boot", "loader=/usr/share/edk2-ovmf/x64/OVMF_CODE.fd," +
        #                "loader.readonly=yes,loader.type=pflash," + 
        #                "nvram.template=/usr/share/edk2-ovmf/x64/OVMF_CODE.fd," +
        #                "loader_secure=no"])
