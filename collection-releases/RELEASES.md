# Collection releases of ST

This document describes some of the practicalities of making a
collection release. What is meant by a an ST collection release (in
contrast to an ST component release) is described at
[releases](https://git.glasklar.is/system-transparency/project/docs/-/tree/main/content/docs/releases).
Related scripts are located in the [releng](../releng) directory.

## Release tags

Collection releases are identified by signed git tags in this
repository, documented in the [NEWS](./NEWS) file, with the format
`st-x.y.z`. The name of the corresponding manifest file is then
`st-x.y.z.manifest`.

## Creating a release archive

The script `mk-release-archive.sh` is used to create a collection
archive. Needed inputs:

* The manifest file.
* The NEWS file (to be copied verbatim into the archive).
* The `allowed-ST-release-signers` file, passed with the `-a` option.

Tags in the manifest must be properly signed (can be overridden using
the `-f` (force) flag, mainly useful during test and development).

## Release testing

To gain confidence in a collection at large, we rely heavily on the
release testing of the individual components that are included.  To also
gain confidence in the claimed compatibility between different
collection releases (such as an older stboot and a newer stmgr), we
assess what's changed manually and make a testing plan based on that.

The script `collection-build-test.sh` can be used to test a release
archive. It takes a single argument, the .tar.gz archive file to test.
It unpacks the archive, runs the tests of the included components, and
produces two ISO files (`stboot.iso` and `stprov.iso`) that are
expected to boot successfully on our lab machine.

Testing of the release archive is intended to be a low-effort "smoke
test" to verify that nothing has gone wrong in the collection packaging.

## Documentation

The docs component is not covered by the above test script. But
component release testing of docs is based on the collection archive,
which means that component testing provides reasonable test coverage
for assembling the complete docs site from a release archive.

## Publishing the release

Make a signed tag in this repo, and sign the release archive.

Upload archive and signature to <https://dist.system-transparency.org>,
and send release email to <st-announce@lists.system-transparency.org>.

## Future extensions

For later releases, we're considering the need to have collection
release testing include more extensive interoperability tests between
collection release versions, than are done as part of component
release testing.
