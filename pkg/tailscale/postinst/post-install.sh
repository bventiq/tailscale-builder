#!/bin/sh
# NOTE: the exact apk-tools script hook name/environment for install scripts
# (e.g. any equivalent to opkg's $IPKG_INSTROOT guard for chroot/offline
# installs) was not confirmed against the compiled host apk binary at
# plan time - verify with `apk mkpkg --help` and adjust before relying on
# this in a chroot/rootfs-build context.
/etc/init.d/tailscale enable
exit 0
