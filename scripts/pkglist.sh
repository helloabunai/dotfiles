#!/bin/bash
# Dump explicitly-installed packages for backup/restore into the dotfiles repo.
# Explicit-only (-Qqe): dependencies resolve themselves on restore, so a 231-entry
# list rebuilds the same 1693-package system without pinning transitive deps.
set -u

OUTDIR=${1:-/home/alastairm/repos/dotfiles/pkglist}
mkdir -p "$OUTDIR"

pacman -Qqen | sort > "$OUTDIR/native.txt"
pacman -Qqem | sort > "$OUTDIR/aur.txt"

REPOS=$(grep -E '^\[' /etc/pacman.conf | tr -d '[]' | grep -v '^options$')
{
  echo "# Repo attribution for native.txt, generated $(date -I)"
  echo "# A package listed under more than one repo is available from each."
  for r in $REPOS; do
    echo
    echo "## $r"
    comm -12 <(paclist "$r" 2>/dev/null | awk '{print $1}' | sort) "$OUTDIR/native.txt"
  done
} > "$OUTDIR/by-repo.txt"

cat > "$OUTDIR/README.md" <<EOF
# Package lists

Generated $(date -I) by \`scripts/pkglist.sh\` on $(hostnamectl hostname 2>/dev/null || hostname).

| File | Count | Purpose |
|---|---|---|
| \`native.txt\` | $(wc -l < "$OUTDIR/native.txt") | Explicit packages from configured repos |
| \`aur.txt\` | $(wc -l < "$OUTDIR/aur.txt") | Explicit foreign/AUR packages |
| \`by-repo.txt\` | - | Which repo each native package came from |

## Restore

Configure these repos in \`/etc/pacman.conf\` first, or the native install will
fail on anything outside core/extra/multilib:

$(for r in $REPOS; do echo "- \`$r\`"; done)

\`\`\`bash
sudo pacman -S --needed - < native.txt
yay -S --needed - < aur.txt
\`\`\`

Lists are explicit-only, so pacman pulls dependencies itself. Regenerate with
\`scripts/pkglist.sh\`.
EOF

printf "native: %s\naur:    %s\nout:    %s\n" \
  "$(wc -l < "$OUTDIR/native.txt")" "$(wc -l < "$OUTDIR/aur.txt")" "$OUTDIR"
