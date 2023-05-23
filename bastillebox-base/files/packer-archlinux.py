import os
import archinstall
import logging
# from archinstall import User
from archinstall import Profile
from archinstall.lib.models.network_configuration import NetworkConfigurationHandler, NetworkConfiguration
import json

default_profile = {'path': 'minimal'}
default_packages = ['openssh', 'vim', 'wget', 'git', 'ntp']
default_services = ['sshd', 'ntpd']
default_root_password = 'basroot'
default_user = {'sudo': True, 'username': 'bas', '!password': 'bas'}
default_network = {
    'dhcp': True,
    'dns': None,
    'gateway': None,
    'iface': None,
    'ip': None,
    'type': 'nm'
}

def load_json_file(fpath):
    archinstall.log(f"Loading {fpath}:")
    if not os.path.exists(fpath):
        return False

    with open(fpath) as fs:
        content = fs.read()
        parsed_content = json.loads(content)
        return parsed_content

def load_user_credentials(file_name="/tmp/files/user_credentials.json"):
	return load_json_file(file_name)

def load_user_configuration(file_name='/tmp/files/user_configuration.json'):
	return load_json_file(file_name)

def load_disk_layout(file_name='/tmp/files/user_disk_layout.json'): 
	parsed = load_json_file(file_name)
	if not parsed:
		raise FileNotFoundError(f'failure to find {file_name}. This file is required by the custom packer-archlinux installation script.')
	return parsed

def format_disks(block_devices, disk_layouts):
    if not block_devices:
        raise archinstall.DiskError(f'Could not find any disks')

    mode = archinstall.GPT if archinstall.has_uefi() else archinstall.MBR
    for disk in disk_layouts:
        with archinstall.Filesystem(block_devices[disk], mode) as fs:
            print(f" ! Formatting {disk}")
            fs.load_layout(disk_layouts[disk])

def install_latest_keyring():
	archinstall.check_mirror_reachable()
	keyring_package = archinstall.find_package('archlinux-keyring')
	latest_version = max([k.pkg_version for k in keyring_package])
	current_version = archinstall.installed_package('archlinux-keyring').version
	if current_version < latest_version:
		updated = archinstall.update_keyring()
		if not updated:
			archinstall.log(f"Failed to update the keyring. Please check your internet connection.", level=logging.INFO, fg="red")
			exit(1)

def configure_bootloader(installation, bootloader):
	if bootloader == "grub-install" and archinstall.has_uefi():
		installation.add_additional_packages("grub")
	installation.add_bootloader(archinstall.arguments["bootloader"])

def configure_network(installation, network_config):
	if network_config:
		conf = NetworkConfiguration(**network_config)
		handler = NetworkConfigurationHandler(conf)
		handler.config_installer(installation)
	else:
		installation.copy_iso_network_config(enable_services=True)

def configure_additional_packages(installation, custom_packages):
	installation.add_additional_packages(custom_packages)

def configure_services(installation, services):
	installation.enable_service(*services)

def configure_root_password(installation, root_password):
	if len(root_password):
		installation.user_set_pw('root', root_password)

def configure_users(users):
    def sanitize(user):
        sanitized = dict(user)
        print("test 0: ", sanitized)
        sanitized['password'] = sanitized['!password']
        del sanitized['!password']
        print("test 1: ", sanitized)
        return sanitized
    sanitize(users[0])

    # installation.create_users([User(**sanitize(x)) for x in users])

def configure_timezone(installation, timezone):
	installation.set_timezone(timezone)

def configure_swap(installation, enable_swap):
	if enable_swap:
		installation.setup_swap('zram')

def configure_keyboard_layout(installation, keyboard_layout):
	installation.set_keyboard_language(keyboard_layout)

def install_on(mountpoint, disk_layouts):
	bootloader = archinstall.arguments.get('bootloader', 'grub-install')
	custom_packages = archinstall.arguments.get('packages', default_packages)
	hostname = archinstall.arguments.get('hostname', 'packer-archlinux')
	kernels = archinstall.arguments.get('kernels', ['linux'])
	keyboard_layout = archinstall.arguments.get('keyboard-layout', 'us').upper()
	network_config = archinstall.arguments.get('nic', default_network)
	root_password = archinstall.arguments.get('!root-password', default_root_password)
	services = archinstall.arguments.get('services', default_services)
	sys_encoding = archinstall.arguments.get('sys-encoding', 'UTF-8').upper()
	sys_language = archinstall.arguments.get('sys-language', 'fr_BE')
	timezone = archinstall.arguments.get('timezone', 'CET')
	users = archinstall.arguments.get('!users', default_user)
	custom_commands = archinstall.arguments.get('custom-commands', None)
	swap = archinstall.arguments.get('swap', False)

	locales = [f"{sys_language} {sys_encoding}"]
	with archinstall.Installer(
		mountpoint, kernels=kernels
	) as installation:
		installation.mount_ordered_layout(disk_layouts)
		if installation.minimal_installation(
			hostname=hostname, locales=locales,
		):
			profile_path = archinstall.arguments.get('profile', default_profile)['path']
			profile = Profile(installation, profile_path)
			# the profile is referenced as a global variable by further installation steps
			# this is undesirable, but will require further investigation (reading through archinstall)
			archinstall.arguments['profile'] = profile

			installation.install_profile('minimal')
			configure_bootloader(installation, bootloader)
			configure_network(installation, network_config)
			configure_users(users)
			configure_root_password(installation, root_password)
			configure_additional_packages(installation, custom_packages)
			configure_services(installation, services)
			configure_timezone(installation, timezone)
			configure_swap(installation, swap)
			configure_keyboard_layout(installation, keyboard_layout)

			if custom_commands:
				archinstall.run_custom_user_commands(
					custom_commands, installation)

			installation.genfstab()

	archinstall.log("There is one account in your installation after reboot:")
	archinstall.log(" * bas (password: bas)")

def unattended_installer():
	"""
	This "profile" is a meta-profile.
	The actual profile used is "minimal" by default, but others may be supported (untested.)
	"""
	if user_credentials := load_user_credentials():
		archinstall.arguments.update(user_credentials)

	if user_configuration := load_user_configuration():
		archinstall.arguments.update(user_configuration)

	disk_layouts = load_disk_layout()

	# install_latest_keyring()

	block_devices = archinstall.all_blockdevices()
	print(f'block_devices: {block_devices}')
	format_disks(block_devices, disk_layouts)
	print(f'disk_layouts: {disk_layouts}')
	install_on('/mnt/archinstall', disk_layouts)

unattended_installer()
