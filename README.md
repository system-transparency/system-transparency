# System Transparency

This repository is used for managing ST [collection releases][]. It is
mainly useful for the maintainers of [System Transparency][].

The documentation of each collection release and its components is
published at <https://docs.system-transparency.org>.

## Overview

* [./NEWS](./NEWS): Summary of changes between collection releases.
  A current copy is included in the release archive for each
  collection release, and relevant excerpts are included with
  release announcements on the [ST-announce][] list.
* [./collection-releases](./collection-releases/): The manifests
  defining which components and versions are part of each collection
  release. Each release archive for a collection release includes
  its manifest.
* [./RELEASES.md](./RELEASES.md): Documents the practicalities of
  how collection releases are prepared and tested, using the scripts
  in this repository.
* [./keys](./keys/): Management of the [official keys][] used for
  signing both component and collection releases of ST.
* [./releng](./releng/): Scripts used to assemble collection-release
  tar files corresponding to a given collection-release manifest.

[collection releases]: https://docs.system-transparency.org/st-1.1.0/docs/releases/
[System Transparency]: https://www.system-transparency.org/
[ST-announce]: https://lists.system-transparency.org/mailman3/hyperkitty/list/st-announce@lists.system-transparency.org/
[official keys]: https://www.system-transparency.org/keys
