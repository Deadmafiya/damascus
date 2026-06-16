#!/bin/bash
# Build the Damascus OS ISO. Self-contained — fast mirrors are embedded
# in iso/damascus/pacman.conf, so this does NOT depend on the host mirrorlist.
#
# Usage:   bash /home/deadmafia/Documents/damascus/assets/build.sh
# Output:  /home/deadmafia/Documents/damascus/assets/iso-out/damascus-*.iso
# Time:    ~5-8 min on a fast mirror
set -e

PROFILE="/home/deadmafia/Documents/damascus/iso/damascus"
# NOTE: work dir must live on a real disk, NOT /tmp — here /tmp is tmpfs (RAM)
# and an archiso build needs ~10G of scratch. /var/tmp is on / (60G free).
WORK="/var/tmp/archiso-work-dma"
OUT="/home/deadmafia/Documents/damascus/assets/iso-out"

# Sanity checks (each prints a clear error if something is wrong)
[[ -d "$PROFILE" ]] || { echo "ERROR: profile dir not found: $PROFILE"; exit 1; }
[[ -f "$PROFILE/profiledef.sh" ]] || { echo "ERROR: profiledef.sh missing"; exit 1; }
[[ -w /dev/null ]] || { echo "ERROR: /dev/null is broken or not writable. Run: sudo mknod /dev/null c 1 3 && sudo chmod 666 /dev/null"; exit 1; }
command -v mkarchiso >/dev/null || { echo "ERROR: mkarchiso not installed. Run: sudo pacman -S --needed archiso"; exit 1; }

# Clean state
echo "==> Cleaning up previous build state..."
sudo rm -rf "$WORK" 2>/dev/null || true
rm -f /var/cache/pacman/pkg/*.part 2>/dev/null || sudo rm -f /var/cache/pacman/pkg/*.part
mkdir -p "$OUT"

# Build
echo "==> Building Damascus OS ISO from $PROFILE"
echo "    work dir:  $WORK"
echo "    out dir:   $OUT"
echo
# Don't let set -e abort before we can report the failure cleanly.
RC=0
time sudo mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE" || RC=$?

echo
if [[ $RC -eq 0 ]]; then
    echo "==> BUILD OK"
    ls -la "$OUT"/damascus-*.iso 2>/dev/null
    echo
    echo "To run, use one of these:"
    echo "  bash /home/deadmafia/Documents/damascus/assets/qemu-test.sh            # GUI window"
    echo "  bash /home/deadmafia/Documents/damascus/assets/boot-test.sh            # headless boot capture"
else
    echo "==> BUILD FAILED (exit $RC)"
    exit $RC
fi
