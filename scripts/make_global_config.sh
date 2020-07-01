#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set magic variables for current file & dir
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${dir}/../" && pwd)"

config="${root}/run.config"

echo 
echo "Creating golbal build configuration"

echo
echo "Enter SSH connection of your provisioning server"
read -rp "URL: " ssh_upload_server
read -rp "User: " ssh_upload_user
read -rp "Path to webroot: " ssh_upload_path
echo
echo "Enter individual inforation for stboot data files"
read -rp "Provisioning Server URL: " provisioning_server_url



cat >"${config}" <<EOL
# System Transparency build configuration.

# This file is sourced by other shell scripts, possibly run by /bin/sh
# (which might not be bash, nor dash).

##############################################################################
# Installation
#
# Following configuration is used during the installation of the tools.
##############################################################################

# Since u-root does not support go modules yet and by default the insatllation
# uses code from the master branch, ST_UROOT_DEV_BRANCH is checked out after 
# downloading source code and before installation. 
ST_UROOT_DEV_BRANCH=stboot


##############################################################################
# STBoot Data
#
# Following configuration is used in various files of the 
# STBoot data partition.
##############################################################################

# ST_PROVISIONING_SERVER_URL ends up in stboot/data/provisioning-servers.json
# which determines where bootballs are being fetched from. You can add
# additional ones in provisioning-servers.json manually.
ST_PROVISIONING_SERVER_URL=${provisioning_server_url}

# The following settings goes into network.json file on the data partition
# and are used for the network setup of the host. When empty DHCP will be used.
# DNS setting is optional.
ST_HOST_IP=""
ST_HOST_GATEWAY=""
ST_HOST_DNS=""

# QEMU static network settings
#ST_HOST_IP="10.0.2.15/24"
#ST_HOST_GATEWAY="10.0.2.2/24"
#ST_HOST_DNS=""


##############################################################################
# STBoot Bootloader - common
#
# Following configuration is used during the creation linuxboot initramfs.
# The STBoot bootloader is part of this initramfs.
##############################################################################

# ST_INCLUDE_CORE_TOOLS controls if further core utilities are included beside
# the bootloader. This is usefull for debugging purposes. If a initramfs with
# minimal footprint is needed, set to 'n'.
ST_INCLUDE_CORE_TOOLS=y

# ST_ROOTCERT_FINGERPRINT_FILE must contain the fingerprint of the root
# certificate of the signing keys.
ST_ROOTCERT_FINGERPRINT_FILE="${root}/keys/signing_keys/rootcert.fingerprint"

# The minimum number of signatures that must be valid in order to boot the
# downloaded operation system.
ST_HOSTVARS_NUM_SIGNATURES=3

# ST_HOSTVARS_BOOTMODE controlls wether the bootball is loaded from the network
# or from local storage
#ST_HOSTVARS_BOOTMODE=NetworkStatic
#ST_HOSTVARS_BOOTMODE=NetworkDHCP
ST_HOSTVARS_BOOTMODE=LocalStorage


##############################################################################
# STBoot Bootloader - mixed-firmware deployment
#
# Following configuration is used while creating the disk image for 
# mixed firmware systems.
##############################################################################

# ST_LINUXBOOT_CMDLINE ends up in deploy/mixed-firmware/syslinux.cfg and
# controlls the kernel cmdline of the linuxboot kernel. Flags to stboot
# can be passed via uroot.uinitargs here as well.
ST_MIXED_FIRMWARE_LINUXBOOT_CMDLINE='console=ttyS0,115200 uroot.uinitargs="-debug"'

# ST_MIXED_FIRMWARE_LINUXBOOT_KERNEL_CONFIG is the linux kernel defconfig
# loaded before the kernel is beeing built.
ST_MIXED_FIRMWARE_LINUXBOOT_KERNEL_CONFIG="${root}/stboot/mixed-firmware/x86_64_x11ssh_qemu_linuxboot.defconfig"


##############################################################################
# STBoot Operations System Bootballs - Debian Buster
#
# Following configuration is used while creating the bootball with the final 
# operating system.
##############################################################################

# ST_BOOTBALL_OUT names the output directory of the created bootball.
ST_BOOTBALL_OUT=${root}/bootballs

# ST_BOOTBALL_LABEL is the name of the bootball
ST_BOOTBALL_LABEL="System Transparency with Debian Buster"

# ST_BOOTBALL_OS_KERNEL path to the operating system's linux kernel
ST_BOOTBALL_OS_KERNEL=${root}/operating-system/debian/docker/out/debian-buster-amd64.vmlinuz

# ST_BOOTBALL_OS_INITRAMFS path to the cpio archive. This must contain the complete OS.
ST_BOOTBALL_OS_INITRAMFS=${root}/operating-system/debian/docker/out/debian-buster-amd64.cpio.gz

# ST_BOOTBALL_OS_CMDLINE is the kernel command line of the final
# operating system 
ST_BOOTBALL_OS_CMDLINE="console=tty0 console=ttyS0,115200n8 rw rdinit=/lib/systemd/systemd"

# ST_BOOTBALL_TBOOT is the path to the tboot kernel to be used with the bootball
#ST_BOOTBALL_TBOOT=${root}/tboot/tboot.gz
ST_BOOTBALL_TBOOT=""

# ST_BOOTBALL_TBOOT_ARGS is the tboot kernel's command line
ST_BOOTBALL_TBOOT_ARGS=""

# ST_BOOTBALL_ACM is the path to an authenticated code module (ACM) or to a directory containing
# multiple ACMs. All ACMs will be present in the bootball and tboot will pick the right one for the host.
#ST_BOOTBALL_ACM=${root}/tboot/ACM/6th_7th_gen_i5_i7-SINIT_79.bin
ST_BOOTBALL_ACM=""

# ST_BOOTBALL_ALLOW_NON_TXT controlls if the bootball schould be boot with a fallback
# configuration without tboot, when txt is not supported by the host machine.
ST_BOOTBALL_ALLOW_NON_TXT=y
#ST_BOOTBALL_ALLOW_NON_TXT=n

# ST_BOOTBALL_ROOT_CERTIFICATE is the root certificate of the certificates
# used to sign the bootball. It will be included into the bootball.
ST_BOOTBALL_ROOT_CERTIFICATE=${root}/keys/signing_keys/root.cert

##############################################################################
# Upload 
#
# The script upoad_bootball.sh uses this data during uplaod.
# Upload is done via scp, so make sure ssh key are setup right on the server.
##############################################################################

# SSH settings used in stconfig/upload_bootball.sh
# to copy files to your provisioning server.
# ST_SSH_UPLOAD_SERVER is the domain of the provisioning server.
ST_SSH_UPLOAD_SERVER=${ssh_upload_server}

# ST_SSH_UPLOAD_USER is the username at the provisioning server.
ST_SSH_UPLOAD_USER=${ssh_upload_user}

# ST_SSH_UPLOAD_PATH is the web root of the provisioning server.
ST_SSH_UPLOAD_PATH=${ssh_upload_path}


##############################################################################
# Testing
##############################################################################

# ST_QEMU_MEM is the amount of RAM for qemu guests, in megabytes.
ST_QEMU_MEM=2048
EOL

echo 
echo "$0 created."
echo "Further configurations are set to defaults."
read -rp "Press any key to continue" x
