#!/bin/bash
# Test the Damascus OS ISO in QEMU.
# Usage: bash /home/deadmafia/Documents/damascus/assets/qemu-test.sh [--uefi] [--ssh]
set -e

ISO_DIR="/home/deadmafia/Documents/damascus/assets/iso-out"
ISO=$(ls -1t "$ISO_DIR"/damascus-*.iso 2>/dev/null | head -1)

if [[ -z "$ISO" ]]; then
    echo "No ISO found in $ISO_DIR"
    echo "Build first:  bash /home/deadmafia/Documents/damascus/assets/build.sh"
    echo "  (or:        sudo mkarchiso -v -w /tmp/archiso-work-dma -o $ISO_DIR /home/deadmafia/Documents/damascus/iso/damascus)"
    exit 1
fi

echo "Booting: $ISO"
echo "Size:    $(du -h "$ISO" | cut -f1)"
echo

MODE="bios"
SSH_PORT=""
PORT_FWD=""
for arg in "$@"; do
    case $arg in
        --uefi) MODE="uefi" ;;
        --ssh)  SSH_PORT=2222; PORT_FWD=",hostfwd=tcp::2222-:22" ;;
    esac
done

QEMU_BASE=(
    qemu-system-x86_64
    -m 2G
    -enable-kvm
    -smp 2
    -cdrom "$ISO"
    -boot d
    -netdev user,id=n0$PORT_FWD
    -device virtio-net-pci,netdev=n0
    -drive file=/tmp/damascus-disk.qcow2,format=qcow2,if=virtio
)

if [[ "$MODE" == "uefi" ]]; then
    OVMF_CODE=$(ls /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/ovmf/x64/OVMF_CODE.4m.fd 2>/dev/null | head -1)
    if [[ -z "$OVMF_CODE" ]]; then
        echo "OVMF firmware not found. Install edk2-ovmf or remove --uefi"
        exit 1
    fi
    QEMU_BASE+=(-bios "$OVMF_CODE")
fi

if [[ ! -f /tmp/damascus-disk.qcow2 ]]; then
    qemu-img create -f qcow2 /tmp/damascus-disk.qcow2 20G
fi

if [[ -n "$SSH_PORT" ]]; then
    echo "SSH will be available at: ssh -p $SSH_PORT root@127.0.0.1"
fi

echo "QEMU starting... (Ctrl+A X to exit, or close window)"
echo

exec "${QEMU_BASE[@]}"
