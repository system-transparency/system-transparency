## Table of Content
Directory | Description
------------ | -------------
[`/`](../../README.md#scripts) | entry point
[`configs/`](../../configs/README.md#configs) | configuration of operating systems
[`deploy/`](../README.md#deploy) | scripts and files to build firmware binaries
[`deploy/coreboot-rom/`](README.md#deploy-coreboot-rom) | (work in progress)
[`deploy/mixed-firmware/`](../mixed-firmware/README.md#deploy-mixed-firmware) | disk image solution
[`keys/`](../../keys/README.md#keys) | example certificates and signing keys
[`operating-system/`](../../operating-system/README.md#operating-system) | folders including scripts ans files to build reprodu>
[`operating-system/debian/`](../../operating-system/debian/README.md#operating-system-debian) | reproducible debian buster
[`operating-system/debian/docker/`](../../operating-system/debian/docker/README.md#operating-system-debian-docker) | docker environment
[`stboot/`](../../stboot/README.md#stboot) | scripts and files to build stboot bootloader from source
[`stboot/include/`](../../stboot/include/README.md#stboot-include) | fieles to be includes into the bootloader's initramfs
[`stconfig/`](../../stconfig/README.md#stconfig) | scripts and files to build the bootloader's configuration tool from >

## Deploy Coreboot-ROM
Work in progress ...

This are some draft notes to build a coreboot image for the Supermicro X11SSH (only with system >=gcc-7)

### Build Coreboot
```
sudo apt-get install -y bison build-essential curl flex git gnat libncurses5-dev m4 zlib1g-dev pkgconf libssl-dev uuid-dev
git clone https://review.coreboot.org/coreboot
cd coreboot
git checkout c2ce370f30b60daf60e23182cf01eb898d35fbbd
git fetch "https://review.coreboot.org/coreboot" refs/changes/04/32704/5 && git cherry-pick FETCH_HEAD
git fetch "https://review.coreboot.org/coreboot" refs/changes/05/32705/7 && git cherry-pick FETCH_HEAD
git fetch "https://review.coreboot.org/coreboot" refs/changes/44/38344/2 && git cherry-pick FETCH_HEAD
git fetch "https://review.coreboot.org/coreboot" refs/changes/04/38404/1 && git cherry-pick FETCH_HEAD
make crossgcc-i386 CPUS=$(nproc)
cp ../x11ssh-tf.defconfig .config
git submodule update --checkout --init
make -C util/ifdtool/
```
### Extract the vendor firmware from the X11SSH
Use Flashrom from the coreboot repo (maybe install `libpci-dev`)
```
cd ../
https://review.coreboot.org/flashrom
cd flashrom
make
```
Connect Flasher to the board and test cobbection a few times (ch341a_spi flasher is used here)
```
sudo./flashrom -p ch341a_spi
```
Read out the vendor firmware several times and check for read errors
```
sudo ./flashrom -p ch341a_spi -r bios.1
sudo ./flashrom -p ch341a_spi -r bios.2
sudo ./flashrom -p ch341a_spi -r bios.3
diff bios.1 bios.2
diff bios.1 bios.3
```
Save the dumo as `original_vendor_bios_dump.bin` in the coreboot dir

### Build Coreboot continued
Get ME and fd blob out of vendor firmware:
```
./util/ifdtool -x original_vendor_bios_dump.bin
mkdir -p 3rdparty/blobs/mainboard/supermicro/x11-lga1151-series/
cp ../blobs/{me.bin,descriptor.bin} 3rdparty/blobs/mainboard/supermicro/x11-lga1151-series/
make menuconfig
BUILD_TIMELESS=1 make
```
The coreboot image is in build/coreboot.rom
LinuxBoot payload integration:
Copy the linuxboot kernel and initramfs including stboot here (e.g from the mixed-firmware workflow)
After running the tooling they are in 
`deploy/mixed-firmware/vmlinuz-linuxboot`
`stboot/initramfs-linuxboot.cpio`

```
gzip -9 initramfs.cpio
./build/cbfstool ./build/coreboot.rom add-payload -r COREBOOT -f kernel -n fallback/payload -C "console=ttyS0,115200 ro" -I initramfs.cpio.gz
```
### Flash X11SSH via bmc:
Link to the tool: https://www.supermicro.com/en/solutions/management-software/ipmi-utilities
At the bottom of the page you can download the SMCIPMITool.
```
SMCIPMITool ip user pass bios update coreboot.rom -F -N -MER
SMCIPMITool ip user pass ipmi power reset/up/down/staus
```

### Flash X11SSH manually (alternatively)
```
sudo ./flashrom -p ch341a_spi --ifd -i bios -w ../coreboot/build/coreboot.rom
```
