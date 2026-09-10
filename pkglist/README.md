# Package lists

Generated 2026-09-10 by `scripts/pkglist.sh` on winterspring.

| File | Count | Purpose |
|---|---|---|
| `native.txt` | 211 | Explicit packages from configured repos |
| `aur.txt` | 20 | Explicit foreign/AUR packages |
| `by-repo.txt` | - | Which repo each native package came from |

## Restore

Configure these repos in `/etc/pacman.conf` first, or the native install will
fail on anything outside core/extra/multilib:

- `core`
- `extra`
- `multilib`
- `chaotic-aur`
- `lizardbyte`
- `lizardbyte-beta`

```bash
sudo pacman -S --needed - < native.txt
yay -S --needed - < aur.txt
```

Lists are explicit-only, so pacman pulls dependencies itself. Regenerate with
`scripts/pkglist.sh`.
