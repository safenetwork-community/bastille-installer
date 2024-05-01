extern crate simple_home_dir;

use simple_home_dir::home_dir;

use std::env;
use std::process::{Command, ExitCode, Stdio};

fn main() -> ExitCode {
    let args: Vec<String> = env::args().collect();

    if args.len() != 2 { 
        eprintln!("Usage: setup-vm [MAC_ADDRESS].\n\
        To retrieve the correct mac address, enter \"ip add | grep link/ether | awk \'{{print $2}}\'\"\n\
        on your SE_bastille_installer-box console without double quotes.");
        return ExitCode::FAILURE;
    }

    // Mac address of SE_Bastille-installer_box network device.
    let mac_address = &args[1]; // TODO: automate address retrieval
    
    // File locations
    let path_ssh_key = format!("{}/.ssh/id_bas", home_dir().unwrap().display());
    let path_github_key = format!("{}/.ssh/id_folaht_ybgiht_sds", home_dir().unwrap().display());
    
    let arp_scan = Command::new("arp-scan")
        .arg("--interface=virbr0") 
        .arg("--localnet")
        .stdout(Stdio::piped())
        .spawn()
        .expect("arp_scan failed");
    let grep_mac = Command::new("grep")
        .arg(mac_address)
        .stdin(Stdio::from(arp_scan.stdout.unwrap()))
        .stdout(Stdio::piped())
        .spawn()
        .expect("grep failed");

    let grep_output = grep_mac.wait_with_output().unwrap();
    let grep_string = String::from_utf8(grep_output.stdout).unwrap();
    let ip_address = grep_string.split_once('\t').unwrap().0;

    Command::new("scp")
        .arg("-i")
        .arg(path_ssh_key)
        .arg(path_github_key)
        .arg(format!("bas@{}:~/.ssh", ip_address))
        .status()
        .expect("ssh failed");

    ExitCode::SUCCESS
}
