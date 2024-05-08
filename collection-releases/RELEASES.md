# Collection releases of ST

What is meant by a an ST collection release (in contrast to an ST
component release) is described at
[](https://git.glasklar.is/system-transparency/project/docs/-/tree/main/content/docs/releases).
This document describes some of the practicalities of making a
release. Related scripts are located in the [](../releng) directory.

## Release tags

Collection releases are identified by signed tags on this repository,
documented in the NEWS file, with the format `st-x.y.z`, . The name of
the corresponding manifest file is then `st-x.y.z.manifest`.

## Creating a release archive

The script `mk-release-archive.sh` is used to create a collection
archive. Needed inputs:

* The manifest file.
* The NEWS file (to be copied verbatim into the archive).
* The `allowed-ST-release-signers` file, passed with the `-a` option.

Tags in the manifest must be properly signed (can be overridden using
the `-f` (force) flag, mainly useful during test and development).

## Release testing

We currently rely heavily on the previous release testing of the
component releases included in the collection. Testing of the release
archive is intended to be a low-effort "smoke test" to verify that
nothing has gone wrong in the collection packaging.

The script `collection-build-test.sh` can be used to test a release
archive. It takes a single argument, the .tar.gz archive file to test.
It unpacks the archive, runs the tests of the included components, and
produces two ISO files (`stboot.iso` and `stprov.iso`) that are
expected to boot successfully on our lab machine.

## Documentation

The docs component is not covered by the above test script. But
component release testing of docs is based on the collection archive,
which means that component testing provides reasonable test coverage
for assembling the complete docs site from release archive.

## Future extensions

For later releases, we're considering the need to have collection
release testing include more extensive interoperability tests between
collection release versions, than are done as part of component
release testing.
