#!/bin/bash
# Clone all Arch Linux source repos in parallel
set -u
cd /home/deadmafia/Documents/damascus

LOG=/home/deadmafia/Documents/damascus/assets/clone.log
> "$LOG"

clone_repo() {
    local url="$1"
    local dest="$2"
    echo "[$(date +%H:%M:%S)] START  $url -> $dest" | tee -a "$LOG"
    if git clone --depth=1 "$url" "$dest" >> "$LOG" 2>&1; then
        echo "[$(date +%H:%M:%S)] OK     $dest" | tee -a "$LOG"
    else
        echo "[$(date +%H:%M:%S)] FAIL   $dest" | tee -a "$LOG"
    fi
}

# Heavy ones first
clone_repo https://github.com/archlinux/svntogit-packages.git     packages/svntogit-packages    &
clone_repo https://github.com/archlinux/svntogit-community.git   packages/svntogit-community  &

# Kernel
clone_repo https://github.com/archlinux/linux.git                 kernel                        &

# Build tools
clone_repo https://github.com/archlinux/pacman.git                build-system/pacman           &
clone_repo https://github.com/archlinux/archiso.git              build-system/archiso          &
clone_repo https://github.com/archlinux/devtools.git             build-system/devtools         &
clone_repo https://github.com/archlinux/mkinitcpio.git           build-system/mkinitcpio       &
clone_repo https://github.com/archlinux/arch-install-scripts.git build-system/arch-install-scripts &

wait
echo "[$(date +%H:%M:%S)] ALL CLONES COMPLETE" | tee -a "$LOG"
