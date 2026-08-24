# tailscale-builder

Automatically tracks upstream [Tailscale](https://tailscale.com) releases,
cross-compiles `tailscaled`/`tailscale` for a curated set of OpenWrt
architectures, compresses the binaries with UPX, packages them as OpenWrt
**APKv3 (`.apk`)** packages, and publishes a signed apk repository on GitHub
Pages so routers running **OpenWrt 24.10+** can install and auto-update
Tailscale with `apk update && apk upgrade` — no manual downloads.

> Only OpenWrt 24.10+ (the apk-based releases) are supported. Older releases
> still on `opkg`/`.ipk` are out of scope for this repository — use the
> official [openwrt/packages](https://github.com/openwrt/packages/tree/master/net/tailscale)
> feed instead.

## Supported architectures

| OpenWrt arch | Typical devices |
|---|---|
| `aarch64_generic` | Most 64-bit ARM routers/SBCs |
| `arm_cortex-a7_neon-vfpv4` | 32-bit ARM, e.g. many IPQ40xx-based devices |
| `arm_cortex-a9_neon` | 32-bit ARM, e.g. IPQ806x-class devices |
| `x86_64` | PCs, VMs, NAS boxes |
| `mips_24kc` | Big-endian MIPS, ath79-class routers |
| `mipsel_24kc` | Little-endian MIPS, ramips-class routers |
| `i386_pentium4` | Legacy 32-bit x86 |

Your router's architecture is shown under **System → Software** or via
`apk info -a` / `cat /etc/apk/arch`.

## Installing on your router (one-time setup)

```sh
wget -O /etc/apk/keys/tailscale-builder.pem \
  https://<owner>.github.io/tailscale-builder/keys/tailscale-builder.pem

echo 'v3 https://<owner>.github.io/tailscale-builder/' \
  > /etc/apk/repositories.d/tailscale-builder.list

apk update
apk add tailscale
service tailscale enable
service tailscale start
```

Replace `<owner>` with the GitHub account/organization this repository is
published under.

## Getting updates

```sh
apk update && apk upgrade tailscale
```

To also update everything else on the router: `apk update && apk upgrade`.

For fully hands-off updates you can add a cron entry, e.g.:

```
0 4 * * * apk update && apk upgrade tailscale
```

Test this manually first — an upstream Tailscale update can occasionally
change CLI flags or behavior.

## How it works

A GitHub Actions workflow (`.github/workflows/build-and-publish.yml`) runs
every 6 hours (and on manual dispatch):

1. Checks the latest stable `tailscale/tailscale` GitHub release against the
   version currently published on this repo's GitHub Pages feed.
2. If there's a new version, cross-compiles `tailscaled` for every
   architecture above (`CGO_ENABLED=0`, matching the build tags/ldflags used
   by the official OpenWrt package).
3. Compresses each binary with UPX. **Compression is mandatory** — if it
   fails for an architecture, that architecture's build fails rather than
   shipping an oversized, uncompressed binary to flash-constrained devices.
4. Packages each binary as a `.apk` (`apk mkpkg`), and republishes the signed
   repository index (`Packages.adb`, via `apk mkndx`) for every architecture
   in a single commit to the `gh-pages` branch — only after every
   architecture has built successfully.

See [CONTRIBUTING.md](CONTRIBUTING.md) for maintainer setup (signing key,
GitHub Pages configuration) and known open questions.
