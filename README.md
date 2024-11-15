# System Transparency

This repository is used for managing [collection releases][].  It is
mainly useful for the maintainers of [System Transparency][].

## Overview

  * [./NEWS](./NEWS): complete history of all collection-release
    changes.  Excerpts of this file are published on the
    [ST-announce][] list.  The documentation of each collection
    release is rendered at <https://docs.system-transparency.org/>.
  * [./RELEASES](./RELEASES.md): internal documentation on how the
    maintainers do collection releases using this repository.
  * [./collection-releases](./collection-releases): manifests
    describing which components and versions are part of the different
    collection releases.  These manifests are baked into the
    collection-release tar files at
    <https://dist.system-transparency.org/st>.
  * [./keys](./keys): used for internal key-syncing amongst
    maintainers.  The official [System Transparency][] keys are
    published at <https://www.system-transparency.org/keys>.
  * [./releng](./releng): scripts used to assemble collection-release
    tar files corresponding to a given collection-release manifest.

[collection releases]: https://docs.system-transparency.org/st-1.1.0/docs/releases/
[System Transparency]: https://www.system-transparency.org/
[ST-announce]: https://lists.system-transparency.org/mailman3/hyperkitty/list/st-announce@lists.system-transparency.org/
