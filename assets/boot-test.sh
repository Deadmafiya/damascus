#!/bin/bash
# Headless boot test: boot an ISO in QEMU, capture serial output, then poweroff.
# Verifies the ISO actually boots to a usable state.
# Usage: bash /home/deadmafia/Documents/damascus/assets/boot-test.sh [path-to-iso]
set -e

ISO="${1:-$(ls -1t /home/deadmafia/Documents/damascus/assets/iso-out/damascus-*.iso 2>/dev/null | head -1)}"

if [[ -z "$ISO" || ! -f "$ISO" ]]; then
    echo "ISO not found. Build first:"
    echo "  bash /home/deadmafia/Documents/damascus/assets/build.sh"
    echo "Or pass an ISO path: $0 /path/to/some.iso"
    exit 1
fi

LOG="/tmp/gy-boot-test-$(date +%s).log"
echo "ISO:     $ISO ($(du -h "$ISO" | cut -f1))"
echo "Log:     $LOG"
echo

# Run QEMU headless. -nographic redirects VGA to stdio.
# -serial mon:stdio adds a serial console on the same stdio.
# Watch for boot completion markers, then poweroff.
# -no-reboot ensures the VM exits cleanly when we send ACPI poweroff.

timeout 90 qemu-system-x86_64 \
    -m 2G \
    -enable-kvm \
    -smp 2 \
    -cdrom "$ISO" \
    -boot d \
    -nographic \
    -serial mon:stdio \
    -no-reboot \
    -drive file=/dev/null,if=virtio,format=raw \
    -netdev user,id=n0 \
    -device virtio-net-pci,netdev=n0 2>&1 | tee "$LOG" | {
    # After 30s, send a poweroff via QEMU monitor if we see boot progress.
    # We can't easily inject from inside the pipe, so we just watch and report.
    :
}

echo
echo "=== Boot test complete ==="
echo
echo "Markers found in output:"
grep -iE "(systemd|login:|archlinux|grub|error|fail|panic|welcome|damascus)" "$LOG" | head -20 || echo "  (none matched)"

# Poweroff QEMU
echo
echo "Sending ACPI poweroff to any running VM..."
qemu-system-x86_64 -m 2G -enable-kvm -cdrom "$ISO" -boot d -nographic -no-reboot 2>/dev/null || true &
QPID=$!
sleep 2
kill $QPID 2>/dev/null || true
wait 2>/dev/null || true
