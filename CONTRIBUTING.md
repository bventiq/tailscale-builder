# Maintainer runbook

## One-time repository setup

1. **Generate the apk signing keypair** (do this offline, never in CI):

   ```sh
   openssl ecparam -name prime256v1 -genkey -noout -out tailscale-builder-private.pem
   openssl ec -in tailscale-builder-private.pem -pubout -out tailscale-builder.pem
   ```

2. Register the private key as a repo secret:

   ```sh
   gh secret set APK_SIGNING_KEY --repo <owner>/tailscale-builder < tailscale-builder-private.pem
   ```

   Then delete/secure `tailscale-builder-private.pem` locally — it must never
   be committed.

3. Commit the **public** key only, as `keys/tailscale-builder.pem`.

4. Enable GitHub Pages: **Settings → Pages → Source = Deploy from a branch →
   `gh-pages` / `/ (root)`**. The `gh-pages` branch itself is created
   automatically by the first successful run of the publish workflow.

5. Trigger the workflow once manually (`workflow_dispatch`, `force_rebuild:
   true`) to produce the first release.

## Key rotation

1. Generate a new keypair as above.
2. Update the `APK_SIGNING_KEY` secret with the new private key.
3. Publish the new public key under a **new filename** (e.g.
   `tailscale-builder-2027.pem`) alongside the old one — routers that already
   trust the old key need a grace period before it's removed.
4. Announce the rotation (README/release notes) so users fetch the new key
   into `/etc/apk/keys/`.
5. After a reasonable grace period, remove the old public key file and stop
   referencing it from `index.html`.

## Keeping apk-tools in sync with OpenWrt

`scripts/build-apk-tools.sh` pins a specific `apk-tools` commit
(`APK_TOOLS_REF`, currently the one vendored by `openwrt/openwrt`'s
`package/system/apk`, apk-tools v3.0.5). Because the on-router `apk` client
and our host-built `apk` need to agree on the `.apk`/`Packages.adb` wire
format, periodically check what OpenWrt's current release branch pins and
bump `APK_TOOLS_REF` to match when it moves.

## Known open questions / verify-before-relying-on

- **`apk mkpkg --script` keyword list**: `post-install`, `pre-deinstall`, and
  `post-upgrade` are confirmed (from OpenWrt's `include/package-pack.mk`).
  The full list (e.g. whether `pre-install` exists, and how the second
  `post-deinstall` case we use for disabling the service should really be
  named) should be double-checked against `apk mkpkg --help` once the host
  binary is built, before depending on any additional hook.
- **Per-architecture `apk` client compatibility**: this repo's `.apk` +
  `Packages.adb` feed uses a self-hosted, non-official layout. Test against a
  real (or QEMU-emulated) OpenWrt 24.10+ router end-to-end
  (`apk update && apk add tailscale`) before treating any architecture as
  fully supported — the official `downloads.openwrt.org` package feed was
  still `.ipk`-based as of this writing, so this exact path has limited
  precedent.
- **`GOMIPS` value for `mips_24kc`/`mipsel_24kc`**: currently `softfloat`.
  Some 24Kc-class SoCs do have a hardware FPU; revisit if a particular target
  would benefit from `hardfloat`.
- **UPX per-architecture reliability**: if UPX consistently fails for one of
  the seven architectures (rather than transiently), remove that entry from
  `scripts/lib/arches.json` rather than weakening the "compression is
  mandatory" policy in `scripts/compress-upx.sh`.
