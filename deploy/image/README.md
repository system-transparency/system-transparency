linux kernel config

In addition to x86_64 based defconfig:
'''
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
'''
