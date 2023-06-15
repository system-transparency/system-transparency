# Information on how System Transparency can be tested on real hardware

These scripts and instructions are not generic test scripts, but
rather provides a description of how ST is tested at Glasklar.

File `test-stprov.sh` was used for testing ST R.2. on physical
hardware. It is using the `build-*.sh` scripts.

One of the issues with testing on a real machine is that its serial
port, if it have one, is usually not connected to anything we have
access to. And even if that could be fixed, others might not be so
fortunate. So we build ISO's with kernel(s) that do not have
`console=ttyS0` on the kernel command line.
