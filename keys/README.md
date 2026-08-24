# Signing key (public half)

This directory must contain `tailscale-builder.pem` — the **public** half of
the EC keypair used to sign the published apk repository index
(`Packages.adb`). The private half must never be committed here; it lives
only in the `APK_SIGNING_KEY` GitHub Actions secret.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for how to generate the keypair and
register the secret. The private key generated alongside this public key was
handed to you outside of version control — register it as the
`APK_SIGNING_KEY` GitHub Actions secret and delete/secure your local copy;
it must never be committed here.
