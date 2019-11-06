#terminal
qemu-system-x86_64 -drive if=virtio,file=deploy/image/MBR_Syslinux_Linuxboot.img,format=raw -device virtio-rng-pci -m 8192 -nographic 
