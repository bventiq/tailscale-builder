# Signing key (public half)

This directory must contain `tailscale-builder.pem` — the **public** half of
the EC keypair used to sign the published apk repository index
(`Packages.adb`). The private half must never be committed here; it lives
only in the `APK_SIGNING_KEY` GitHub Actions secret.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for how to generate the keypair and
register the secret. Until `tailscale-builder.pem` exists in this directory,
the publish workflow will fail at the "Assemble and sign" step by design —
that's the signal that initial key setup hasn't been done yet.
