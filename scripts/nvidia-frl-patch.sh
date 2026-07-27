#!/bin/bash
#
# Re-apply NVIDIA open-gpu-kernel-modules PR #1186 (force_frl_rate honors
# EDID-declared FRL caps without live link assessment -> enables 4K@120 HDR on
# forced/headless-EDID HDMI outputs) to the nvidia-open-dkms source, then rebuild.
#
# Invoked by a pacman PostTransaction hook on nvidia-open-dkms upgrades.
# Idempotent, and FAILS LOUD if the patch no longer applies (so a driver
# refactor surfaces as a visible hook error instead of silently dropping 4K@120).
#
# Runtime patch lives at /etc/nvidia-patches/ (this file + the .patch are the
# source-of-truth copies kept in ~/scripts for dotfiles mirroring).
#
# ---------------------------------------------------------------------------
# DEPLOYMENT -- these dotfiles copies are INERT until installed to system paths
# (a pacman hook cannot exec from $HOME, and the patch must live under /etc):
#
#   sudo install -Dm755 nvidia-frl-patch.sh   /usr/local/bin/nvidia-frl-patch.sh
#   sudo install -Dm644 nvidia-frl-1186.patch /etc/nvidia-patches/nvidia-frl-1186.patch
#   sudo install -Dm644 zz-nvidia-frl.hook    /etc/pacman.d/hooks/zz-nvidia-frl.hook
#
# First-time apply (the hook only fires on future nvidia-open-dkms upgrades):
#   sudo /usr/local/bin/nvidia-frl-patch.sh
#
# Enable the feature (cmdline param on the systemd-boot entry's options line):
#   nvidia-modeset.force_frl_rate=1        # 1 = max FRL, 2 = max FRL + DSC
#
# Requires nvidia-open-dkms (NOT the prebuilt nvidia-open). If Secure Boot is on,
# the rebuilt module must be MOK-signed or it won't load.
# ---------------------------------------------------------------------------
set -euo pipefail

PATCH=/etc/nvidia-patches/nvidia-frl-1186.patch
[ -r "$PATCH" ] || { echo "FRL: patch $PATCH not found; skipping"; exit 0; }

# Version of the DKMS 'nvidia' module supplied by nvidia-open-dkms
ver=$(dkms status 2>/dev/null | awk -F'[/,]' '/^nvidia\//{print $2; exit}')
[ -n "${ver:-}" ] || { echo "FRL: nvidia dkms module not registered; skipping"; exit 0; }

src="/usr/src/nvidia-$ver"
[ -d "$src" ] || { echo "FRL: source $src missing; skipping"; exit 0; }

# Idempotent: if the patch reverse-applies, it is already present.
if patch -d "$src" -p1 -R --dry-run -f <"$PATCH" >/dev/null 2>&1; then
  echo "FRL: patch already present in $src"
else
  echo "FRL: applying PR #1186 to $src"
  patch -d "$src" -p1 <"$PATCH"        # fails loud if it no longer applies
fi

echo "FRL: rebuilding nvidia/$ver via dkms"
# 'install --force' only re-installs a cached build; force an actual recompile
# from the freshly-patched source first, or the unpatched cached .ko is reused.
dkms build --force "nvidia/$ver"
dkms install --force "nvidia/$ver"

# nvidia is in the early-KMS initramfs MODULES list, so the patched modules must
# be re-baked into the initramfs. The stock mkinitcpio hook runs during the
# transaction (from the package's UNpatched build) before this PostTransaction
# hook, so we must regenerate here or boot loads the stale unpatched module.
if command -v mkinitcpio >/dev/null; then
  echo "FRL: regenerating initramfs"
  mkinitcpio -P
fi
echo "FRL: done"
