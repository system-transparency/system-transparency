## Table of Content

| Directory                                                                                              | Description                                                    |
| ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| [`/`](../#scripts)                                                                                     | entry point                                                    |
| [`configs/`](../configs/#configs)                                                                      | configuration of operating systems                             |
| [`deploy/`](../deploy/#deploy)                                                                         | scripts and files to build firmware binaries                   |
| [`deploy/coreboot-rom/`](../deploy/coreboot-rom/#deploy-coreboot-rom)                                  | (work in progress)                                             |
| [`deploy/mixed-firmware/`](../deploy/mixed-firmware/#deploy-mixed-firmware)                            | disk image solution                                            |
| [`keys/`](#keys)                                                                                       | example certificates and signing keys                          |
| [`operating-system/`](../operating-system/#operating-system)                                           | folders including scripts ans files to build reprodu>          |
| [`operating-system/debian/`](../operating-system/debian/#operating-system-debian)                      | reproducible debian buster                                     |
| [`operating-system/debian/docker/`](../operating-system/debian/docker/#operating-system-debian-docker) | docker environment                                             |
| [`stboot/`](../stboot/#stboot)                                                                         | scripts and files to build stboot bootloader from source       |
| [`stboot/include/`](../stboot/include/#stboot-include)                                                 | fieles to be includes into the bootloader's initramfs          |
| [`stboot/data/`](../stboot/data/#stboot-data)                                                          | fieles to be placed on a data partition of the host            |
| [`stconfig/`](../stconfig/#stconfig)                                                                   | scripts and files to build the bootloader's configuration tool |

## Keys

This directory contains directories containing some example keys for different tasks:

- `signing_keys`: Contains the keys for signing the bootball
- `cpu_keys`: Contains the keys for using the cpu command for debugging
  - `cpu_rsa`/ `cpu_rsa.pub`: These keys are used for connecting _to_ the machine running the `cpud` server
  - `ssh_host_rsa_key`/ `ssh_host_rsa_key.pub`: These keys are used by the `cpud` server to connect _back to your_ machine.

If these directories seem to be missing, this is because they do not exist by default but are created, by running the `./run.sh` script which in turn runs the `generate_keys_and_certs.sh` script.

### Scripts

#### `generate_keys_and_certs.sh`

This script is invoked by `run.sh`. It generates certificate authority (CA), a self signed root certificate and a set of 5 signing keys, certified by the CA.
