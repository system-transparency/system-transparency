# Deploy Coreboot-ROM

Work in progress ...

This are some draft notes to build a coreboot image for the Supermicro X11SSH (only with system >=gcc-7)

## Build Coreboot

```
sudo apt-get install -y bison build-essential curl flex git gnat libncurses5-dev m4 zlib1g-dev pkgconf libssl-dev uuid-dev
git clone https://review.coreboot.org/coreboot
cd coreboot
make crossgcc-i386 CPUS=$(nproc)
cp ../x11ssh-tf.defconfig .config
git submodule update --checkout --init
make -C util/ifdtool/
```

## Extract the vendor firmware from the X11SSH

Use Flashrom from the coreboot repo (maybe install `libpci-dev`)

```
cd ../
https://review.coreboot.org/flashrom
cd flashrom
make
```

Connect Flasher to the board and test connection a few times (ch341a_spi flasher is used here)

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

## Build Coreboot continued

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

Copy the linuxboot kernel and initramfs including stboot here (e.g from the MBR bootloader workflow)

```
./build/cbfstool ./build/coreboot.rom add-payload -r COREBOOT -f vmlinuz-linuxboot -n fallback/payload -C "console=ttyS0,115200 ro" -I initramfs-linuxboot.cpio.gz
```

## Flash X11SSH via bmc:

Link to the tool: https://www.supermicro.com/en/solutions/management-software/ipmi-utilities
At the bottom of the page you can download the SMCIPMITool.

```
SMCIPMITool ip user pass bios update coreboot.rom -F -N -MER
SMCIPMITool ip user pass ipmi power reset/up/down/staus
```

## Flash X11SSH manually (alternatively)

```
sudo ./flashrom -p ch341a_spi --ifd -i bios -w ../coreboot/build/coreboot.rom
```
