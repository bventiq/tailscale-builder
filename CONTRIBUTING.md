# Maintainer runbook

## One-time repository setup

1. **Generate the apk signing keypair** (do this offline, never in CI):

   ```sh
   openssl ecparam -name prime256v1 -genkey -noout -out tailscale-builder-private.pem
   openssl ec -in tailscale-builder-private.pem -pubout -out tailscale-builder.pem
   ```

   (An initial keypair was already generated for this repo and its public
   half committed at `keys/tailscale-builder.pem`; the private half was
   handed to you outside version control — go straight to step 2 with that
   file unless you're rotating to a fresh keypair.)

2. Register the private key as a repo secret:

   ```sh
   gh secret set APK_SIGNING_KEY --repo <owner>/tailscale-builder < tailscale-builder-private.pem
   ```

   Then delete/secure `tailscale-builder-private.pem` locally — it must never
   be committed.

3. Commit the **public** key only, as `keys/tailscale-builder.pem` (already
   done for the initial keypair; repeat only if rotating).

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

- **`apk mkpkg --script` keyword list**: confirmed by reading apk-tools
  v3.0.5 source (`src/package.c` / `src/apk_adb.c`) — the full and only valid
  set is `pre-install`, `post-install`, `pre-deinstall`, `post-deinstall`,
  `pre-upgrade`, `post-upgrade`. Our use of `post-install`/`post-deinstall`
  is valid.
- **`apk mkndx` requires `--allow-untrusted`**: packages produced by
  `apk mkpkg` without `--sign-key` are unsigned, and `apk mkndx` refuses to
  index them ("UNTRUSTED signature") unless `--allow-untrusted` is passed.
  `scripts/publish-index.sh` passes it; this is intentional — we only sign
  the index itself (`--sign-key` on `mkndx`), not each individual `.apk`,
  matching Alpine's model. Confirmed against a locally built `apk` binary.
- **Per-architecture `apk` client compatibility**: this repo's `.apk` +
  `Packages.adb` feed uses a self-hosted, non-official layout. Test against a
  real (or QEMU-emulated) OpenWrt 24.10+ router end-to-end
  (`apk update && apk add tailscale`) before treating any architecture as
  fully supported — the official `downloads.openwrt.org` package feed was
  still `.ipk`-based as of this writing, so this exact path has limited
  precedent.
- **UPX per-architecture reliability**: if UPX consistently fails for arm64
  or amd64 (rather than transiently), remove that entry from
  `scripts/lib/arches.json` rather than weakening the "compression is
  mandatory" policy in `scripts/compress-upx.sh`.
