## Table of Content

| Directory                                                                                              | Description                                                    |
| ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| [`/`](../#scripts)                                                                                     | entry point                                                    |
| [`configs/`](../configs/#configs)                                                                      | configuration of operating systems                             |
| [`deploy/`](../deploy/#deploy)                                                                         | scripts and files to build firmware binaries                   |
| [`deploy/coreboot-rom/`](../deploy/coreboot-rom/#deploy-coreboot-rom)                                  | (work in progress)                                             |
| [`deploy/mixed-firmware/`](../deploy/mixed-firmware/#deploy-mixed-firmware)                            | disk image solution                                            |
| [`keys/`](../keys/#keys)                                                                               | example certificates and signing keys                          |
| [`operating-system/`](../operating-system/#operating-system)                                           | folders including scripts ans files to build reprodu>          |
| [`operating-system/debian/`](../operating-system/debian/#operating-system-debian)                      | reproducible debian buster                                     |
| [`operating-system/debian/docker/`](../operating-system/debian/docker/#operating-system-debian-docker) | docker environment                                             |
| [`stboot/`](../stboot/#stboot)                                                                         | scripts and files to build stboot bootloader from source       |
| [`stboot/include/`](../stboot/include/#stboot-include)                                                 | fieles to be includes into the bootloader's initramfs          |
| [`stboot/data/`](../stboot/data/#stboot-data)                                                          | fieles to be placed on a data partition of the host            |
| [`stconfig/`](#stconfig)                                                                               | scripts and files to build the bootloader's configuration tool |

## Stconfig

_Stboot_ itself is part of the _u-root_ project (https://github.com/u-root/u-root) and is written in Go. Since _Stboot_ is still in a beta phase at the moment, the code resides at https://github.com/u-root/u-root/tree/stboot branch.

The _u-root_ project also includes some tools related to its various commands. _Stconfig_ is a tool for the host's operator to prepare a bootball file ('stboot.ball') for the provisioning server. This file is downloaded to the host during the _Stboot's_ bootprocess. _Stboot_ is heavily dependent on that bootball being prepared by this tool.
Usually the generated bootball should work for all hosts. But if there is the need for a host specific bootball, you can create a unique bootball identified by the MAC address of the appropriate server. The host will look for a specific boot ball on the provisioning server first. If none is present, the host will download the general one. See `stconfig --help-long` for inforamtion on how to parse the MAC address.

See https://system-transparency.org for further information about 'stconfig.json' and 'stboot.ball'.

### Scripts

#### `install_stconfig.sh`

This script is invoked by 'run.sh'. It downloads and installs the 'stconfig' tool.

#### `create_and_sign_bootball.sh`

This script is invoked by 'run.sh'. It uses 'stconfig' to create a 'stboot.ball' from the 'stconfig.json' in the 'configs/' directory. The path to a dedicated configuration directory is passed to the script. Further it uses 'stconfig' to sign the generated 'stboot.ball' with the example keys from 'keys/'. Optionally you can enter a MAC address to create a host dependent bootball.

#### `upload_bootball.sh`

This script is invoked by 'run.sh'. It uploads the 'stboot.ball' file to the provisioning server. SSH access to the server is needed. See https://system-transparency.org for further information about the provisioning server. Settings regarding your provisioning Server can be done in `prov-server-access.sh`

#### `prov-server-access.sh` (will be generated on first call of `run.sh`)
This file contains information to access the provisioning server via SSH. It is generated with empty values. You need to insert the values according to your setup.

```
# prov_server is the URL of the provisioning server.
prov_server=""

# prov_server_user is the username at the provisioning server.
prov_server_user=""

# prov_server_path is the web root of the provisioning server.
prov_server_path=""
```


