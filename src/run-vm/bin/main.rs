extern crate simple_home_dir;

use regex::Regex;

use simple_home_dir::home_dir;

use std::fs;
use std::process::{Command, ExitCode, Stdio};

fn main() -> ExitCode {
    let re = Regex::new(r"^([0-9A-Fa-f]{1,2}[:-]){5}([0-9A-Fa-f]{1,2})$").unwrap(); 

    // Mac address of SE_Bastille-installer_box network device.
    let mac_address = fs::read_to_string("./packer_cache/mac")
        .unwrap_or_else(|e| panic!("Should have been able to read the file\n{e}"));
    let mac_address = mac_address.trim(); 
    
    match re.is_match(mac_address) {
        true => {
            // File locations  
            let path_ssh_key = format!("{}/.ssh/id_bas", home_dir().unwrap().display());
            
            // Scanning for VM network devices.
            let arp_scan = Command::new("arp-scan")
                .arg("--interface=virbr0") 
                .arg("--localnet")
                .stdout(Stdio::piped())
                .spawn()
                .unwrap_or_else(|e| panic!("arp_scan failed\n{}", e));
            let grep_mac = Command::new("grep")
                .arg(mac_address)
                .stdin(Stdio::from(arp_scan.stdout.unwrap()))
                .stdout(Stdio::piped())
                .spawn()
                .unwrap_or_else(|e| panic!("grep failed\n{}", e));

            let grep_output = grep_mac.wait_with_output().unwrap();
            let grep_string = String::from_utf8(grep_output.clone().stdout);

            match grep_string {
                Ok(result) => {
                    match result.split_once('\t') {
                        Some(output) => {
                            let ip_address = output.0;

                            Command::new("kitten")
                            .arg("ssh").arg("-i")
                            .arg(path_ssh_key)
                            .arg(format!("bas@{}", ip_address))
                            .status()
                            .unwrap_or_else(|e| panic!("ssh failed\n{}", e));

                            return ExitCode::SUCCESS;
                        },
                        None => { 
                            eprintln!("No IP adress found {:?}", grep_output);
                            return ExitCode::FAILURE;
                        },
                    }
                },
                Err(err) => {
                    eprintln!("No IP adress found {:?}", err);
                    return ExitCode::FAILURE;
                },
            }
        },
        false => {
            eprintln!("Invalid MAC address, should be xx:xx:xx:xx:xx:xx, is {mac_address}.\n\
            To retrieve the correct mac address, enter \"ip add | grep link/ether | awk \'{{print $2}}\'\"\n\
            on your SE_bastille_installer-box console without double quotes.");
            return ExitCode::FAILURE;
        },
    }
}
