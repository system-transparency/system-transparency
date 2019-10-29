#terminal
qemu-system-x86_64 -drive if=virtio,file=BIOS_MBR_FAT_Syslinux_Linuxboot_OS.img,format=raw -device virtio-rng-pci -m 8192 -nographic 
