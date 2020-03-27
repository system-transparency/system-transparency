## Table of Content

| Directory                                                                                                       | Description                                                    |
| --------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| [`/`](../README.md#scripts)                                                                                     | entry point                                                    |
| [`configs/`](../configs/README.md#configs)                                                                      | configuration of operating systems                             |
| [`deploy/`](../deploy/README.md#deploy)                                                                         | scripts and files to build firmware binaries                   |
| [`deploy/coreboot-rom/`](../deploy/coreboot-rom/README.md#deploy-coreboot-rom)                                  | (work in progress)                                             |
| [`deploy/mixed-firmware/`](../deploy/mixed-firmware/README.md#deploy-mixed-firmware)                            | disk image solution                                            |
| [`keys/`](../keys/README.md#keys)                                                                               | example certificates and signing keys                          |
| [`operating-system/`](../operating-system/README.md#operating-system)                                           | folders including scripts ans files to build reprodu>          |
| [`operating-system/debian/`](../operating-system/debian/README.md#operating-system-debian)                      | reproducible debian buster                                     |
| [`operating-system/debian/docker/`](../operating-system/debian/docker/README.md#operating-system-debian-docker) | docker environment                                             |
| [`stboot/`](../stboot/README.md#stboot)                                                                         | scripts and files to build stboot bootloader from source       |
| [`stboot/include/`](../stboot/include/README.md#stboot-include)                                                 | fieles to be includes into the bootloader's initramfs          |
| [`stboot/data/`](../stboot/data/README.md#stboot-data)                                                          | fieles to be placed on a data partition of the host            |
| [`stconfig/`](README.md#stconfig)                                                                               | scripts and files to build the bootloader's configuration tool |

## Stconfig

_Stboot_ itself is part of the _u-root_ project (https://github.com/u-root/u-root) and is written in Go. Since _Stboot_ is still in a beta phase at the moment, the code resides at https://github.com/u-root/u-root/tree/stboot branch. This directory mainly provides utilities for the ongoing development.

The _u-root_ project also includes some tools related to its various commands. _Stconfig_ is a tool for the host's operator to prepare a 'stboot.ball' file for the provisioning server. This file is downloaded to the host during the _Stboot's_ bootprocess. _Stboot_ is heavily dependent on that 'stboot.ball' being prepared by this tool.

See https://system-transparency.org for further information about 'stconfig.json' and 'stboot.ball'.

### Scripts

#### `install_stconfig.sh`

This script is invoked by 'run.sh'. It downloads and installs the 'stconfig' tool.

#### `create_and_sign_bootball.sh`

This script is invoked by 'run.sh'. It uses 'stconfig' to create a 'stboot.ball' from the 'stconfig.json' in the 'configs/' directory. The path to a dedicated configuration directory is passed to the script. Further it uses 'stconfig' to sign the generated 'stboot.ball' with the example keys from 'keys/'.

#### `upload_bootball.sh`

This script is invoked by 'run.sh'. It uploads the 'stboot.ball' file to the provisioning server. SSH access to the server is needed. See https://system-transparency.org for further information about the provisioning server.
