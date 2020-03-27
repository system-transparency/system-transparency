## Table of Content

| Directory                                                                                                 | Description                                                    |
| --------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| [`/`](../../#scripts)                                                                                     | entry point                                                    |
| [`configs/`](../../configs/#configs)                                                                      | configuration of operating systems                             |
| [`deploy/`](../../deploy/#deploy)                                                                         | scripts and files to build firmware binaries                   |
| [`deploy/coreboot-rom/`](../../deploy/coreboot-rom/#deploy-coreboot-rom)                                  | (work in progress)                                             |
| [`deploy/mixed-firmware/`](../../deploy/mixed-firmware/#deploy-mixed-firmware)                            | disk image solution                                            |
| [`keys/`](../../keys/#keys)                                                                               | example certificates and signing keys                          |
| [`operating-system/`](../../operating-system/#operating-system)                                           | folders including scripts ans files to build reprodu>          |
| [`operating-system/debian/`](../../operating-system/debian/#operating-system-debian)                      | reproducible debian buster                                     |
| [`operating-system/debian/docker/`](../../operating-system/debian/docker/#operating-system-debian-docker) | docker environment                                             |
| [`stboot/`](../#stboot)                                                                                   | scripts and files to build stboot bootloader from source       |
| [`stboot/include/`](../include/#stboot-include)                                                           | fieles to be includes into the bootloader's initramfs          |
| [`stboot/data/`](#stboot-data)                                                                            | fieles to be placed on a data partition of the host            |
| [`stconfig/`](../../stconfig/#stconfig)                                                                   | scripts and files to build the bootloader's configuration tool |

## Stboot Data

Files in this foder are ment to be places at a data partition at the host machine. This partition will be mounted by the bootloader.

### Scripts

#### `create_example_data.sh`

This script is invoked by 'run.sh'. It creates the files listed below with example data.

### Configuration Files

#### `network.json` (will be generated)

See https://www.system-transparency.org/usage/network.json

#### `provisioning-servers.json` (will be generated)

See https://www.system-transparency.org/usage/provisioning-servers.json

#### `https-root-certificates.pem` (will be generated)

See https://www.system-transparency.org/usage/https-root-certificates.pem

#### `ntp-servers.json` (will be generated)

See https://www.system-transparency.org/usage/ntp-servers.json
