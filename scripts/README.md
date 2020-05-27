
### Scripts

#### `run.sh`

This script is the global entry point to build up or update the environment.
It runs a dependency check and prompts you to execute all other necessary scripts and thereby leads through the whole setup process. Each step can be run, run with special options where applicable or skipped. In this way you can also only renew certain parts of the environment.
Run each step when executing for the first time. Some scripts need root privileges.

The file `run.config` contains configuration variables and should be edited prior to the running of `run.sh`.

#### `start_qemu_mixed-firmware.sh`

This script is invoked by `run.sh`. It will boot up _qemu_ to test the system. All output is printed to the console.
Use `ctrl+a` , `x` to terminate.


#### `install_stconfig.sh`

This script is invoked by 'run.sh'. It downloads and installs the 'stconfig' tool.

#### `install_u-root.sh`

This script is invoked by 'run.sh'. It downloads the source code for the 'u-root' command and the _Stboot_ bootloader and compiles them. Further it installs a special _uinit_ binary from https://github.com/system-transparency/uinit needed to call the bootloader from the initramfs' init-script.

#### `create_and_sign_bootball.sh`

This script is invoked by 'run.sh'. It uses 'stconfig' to create a 'stboot.ball' from the 'stconfig.json' in the 'configs/' directory. The path to a dedicated configuration directory is passed to the script. Further it uses 'stconfig' to sign the generated 'stboot.ball' with the example keys from 'keys/'. Optionally you can enter a MAC address to create a host dependent bootball.

#### `upload_bootball.sh`

This script is invoked by 'run.sh'. It uploads the 'stboot.ball' file to the provisioning server. SSH access to the server is needed. See https://system-transparency.org for further information about the provisioning server. Settings regarding your provisioning Server can be done in `prov-server-access.sh`

#### `prov-server-access.sh` (will be generated on first call of `run.sh`)
This file contains information to access the provisioning server via SSH. It is generated with empty values. You need to insert the values according to your setup.

```
# prov_server is the URL of the provisioning server.
prov_server=""

# prov_server_user is the username at the provisioning server.
prov_server_user=""

# prov_server_path is the web root of the provisioning server.
prov_server_path=""
```

#### `generate_keys_and_certs.sh`

This script is invoked by `run.sh`. It generates certificate authority (CA), a self signed root certificate and a set of 5 signing keys, certified by the CA.

#### `create_stconfig.sh`

This script is invoked by `run.sh`. It creates a configuration directory for the _debian_ system in `configs/` including a `stconfig.json` configuration file. This can also serve as template for custom configuration directories.

See https://system-transparency.org for further information about `stconfig.json`

#### `create_example_data.sh`

This script is invoked by 'run.sh'. It creates the files listed below with example data. Most of the default data can be used right away, but you will probably need to change the URL of the provisioning server in `provisioning-servers.json`.


### Configuration Files

#### `network.json` (will be generated)

See https://www.system-transparency.org/usage/network.json

#### `provisioning-servers.json` (will be generated)

See https://www.system-transparency.org/usage/provisioning-servers.json

#### `https-root-certificates.pem` (will be generated)

See https://www.system-transparency.org/usage/https-root-certificates.pem

#### `ntp-servers.json` (will be generated)

See https://www.system-transparency.org/usage/ntp-servers.json

#### `create_hostvars.sh`

This script is invoked by 'run.sh'. It creates an example 'hostvars.json' file. This can be used as a template for a custom 'hostvars.json'. See https://system-transparency.org for further information about this configuration file.
Choose one of the following flags when calling:

- `d` : empty IP. This will trigger DHCP
- `q` : IP configuration suitable for _QEMU_

#### `make_initrmafs.sh`

This script is invoked by 'run.sh'. It uses the 'u-root' command to build 'initramfs-linuxboot.cpio' including the _uinit_ binary, the _Stboot_ bootloader and further files from the 'include/' directory.
This 'initramfs-linuxboot.cpio' is the core component of each deployment solution of _System Transparency's_ firmware part.

This script accepts a '-d' flag. It then includes the full set of available _Go_ commands into the initfamfs to enable debugging — e.g before _uinit_ hands over control to the _Stboot_ bootloader or in case of a bootloader panic.

#### `build_kernel.sh`

This script is invoked by 'run.sh'. It downloads and veriifys sours code for Linux kernel version 4.19.6. The kernel is build according to 'x86_64_linuxboot_config' file. This kernel will be used as part of linuxboot. The script writes 'vmlinuz-linuxboot' in this directory.

#### `create_image.sh`

This script is invoked by 'run.sh'. Firstly it creates a raw image, secondly _sfdisk_ is used to write the partitions table. Thirdly the script downloads _Syslinux_ bootloader and installs it to the Master Boot Record and the Partition Boot Record respectively. Finally, the _linuxboot_ kernel 'vmlinuz-linuxboot' is copied to the image. The output is 'MBR_Syslinux_Linuxboot.img'.

Notice that the image is incomplete at this state. The appropriate initramfs need to be included.

#### `mount_boot.sh`

This script is for custom use. If you want to inspect or modify files of the boot partition (1st partition) of 'Syslinux_Linuxboot.img' use this script. It mounts the image via a loop device at a temporary directory. The path is printed to the console.

#### `mount_data.sh`

This script is for custom use. If you want to inspect or modify files of the data partition (2nd partition) of 'Syslinux_Linuxboot.img' use this script. It mounts the image via a loop device at a temporary directory. The path is printed to the console.

#### `mv_hostvars_to_image.sh`

Optional at the moment. This Script copies the 'hostvars.json' configuration file to the image.

#### `mv_initrd_to_image.sh`

this script is invoked by 'run.sh'. It copies the linuxboot initramfs including _stboot_ to the image.

#### `umount_boot.sh`

Counterpart of 'mount_boot.sh'.

#### `umount_data.sh`

Counterpart of 'mount_data.sh'.

### Configuration Files

#### `gpt.table`

This files describes the partition layout of the image

#### `syslinux.cfg`

This is the configuration file for _Syslinux_. The paths for kernel and initramfs are set here. Further the kernel command line can be adjusted to controll the behavior of stboot as well. The default looks like this:
```
DEFAULT linuxboot

LABEL linuxboot
	KERNEL ../vmlinuz-linuxboot
	APPEND console=ttyS0,115200 uroot.uinitargs="-debug"
	INITRD ../initramfs-linuxboot.cpio.gz
```
To controll the output of stboot there are the following options for the kernel command line:

* print output to multiple consoles: `console=tty0 console=ttyS0,115200 printk.devkmsg=on uroot.uinitargs="-debug -klog"` (input is still taken from the last console defined. Furthermore it can happen that certain messages are only displayed on the last console)

* print minimal output: `console=ttyS0,115200`


#### `x86_64_linuxboot_config`

This is the kernel config for the _linuxboot_ kernel. In addition to x86_64 based _defconfig_ the following is set:

```
Processor type and features  --->
    [*] Linux guest support --->
        [*] Enable Paravirtualization code
        [*] KVM Guest support (including kvmclock)
        [*] kexec file based system call
        [*] kexec jump

Device Drivers  --->
    Virtio drivers  --->
        <*> PCI driver for virtio devices
    [*] Block devices  --->
        <*> Virtio block driver
        [*]     SCSI passthrough request for the Virtio block driver
    Character devices  --->
        <*> Hardware Random Number Generator Core support  --->
            <*>   VirtIO Random Number Generator support
```