# Release signing keys

This directory records the keys used for signing releases for the System
Transparency project. To verify release signatures, one needs the
`allowed-ST-release-signers` file in this directory.

## Verifying git release tags

To verify a release git tag, e.g., vX.Y.Z, use
```
git -c gpg.format=ssh -c gpg.ssh.allowedSignersFile=allowed-ST-release-signers tag --verify vX.Y.Z
```

If desired, the settings can be made more permanent using `git config`.

## Verifying release archives and other artifacts

To verify the signature on a release artifact, e.g, `foo.tar.gz` with
signature `foo.tar.gz.sig`, use
```
ssh-keygen -Y verify -f allowed-ST-release-signers -I releases@system-transparency.org -n file -s foo.tar.gz.sig  < foo.tar.gz
```

## Signatures on the `allowed-ST-release-signers` file

The `allowed-ST-release-signers` file is self-signed with each listed key
(except temporarily, see Updates below). E.g., the self signature by
key-holder nisse can be verified using
```
ssh-keygen -Y verify -f allowed-ST-release-signers -I nisse@glasklarteknik.se -n file -s allowed-ST-release-signers.nisse.sshsig < allowed-ST-release-signers
```

The file may also be signed using OpenPGP. Files
`allowed-ST-release-signers.*.pgpsig` should be valid detached OpenPGP
signatures, which can be verified with GnuPG (provided that the needed public key
is available) using
```
gpg --verify allowed-ST-release-signers.foo.pgpsig allowed-ST-release-signers
```

## Updates

At all times, all signature files should be valid, and there should be
at least one valid signature; when the allowed signers file is updated,
the person updating the file is expected to sign it, and remove previous
signatures that don't apply to the updated version. Those older
signatures stay available in git history. Key holders are expected to
coordinate the update, so that they can all sign the updated file and
add their new signatures to this directory, as soon as practical.
