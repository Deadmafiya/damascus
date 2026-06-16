# Damascus OS — Custom Arch-Based Distribution

Forging Damascus OS from Arch Linux source. A live ISO built with `archiso`
from a customized profile, focused on being **hacker-friendly**: a lean live
image plus an on-demand pentest arsenal pulled from the official Arch repos.

Project workspace: `/home/deadmafia/Documents/damascus/`

## Quick start

```bash
# 1. Build the ISO (one-time setup, then runs unattended, ~5-8 min)
bash /home/deadmafia/Documents/damascus/assets/build.sh

# 2a. Run with GUI window (interactive)
bash /home/deadmafia/Documents/damascus/assets/qemu-test.sh

# 2b. Run headless and capture boot log
bash /home/deadmafia/Documents/damascus/assets/boot-test.sh
```

Default login on the live ISO: `root` (no password — archiso convention).

## Build prerequisites

* `/usr/bin/mkarchiso` — install: `sudo pacman -S --needed archiso`
* `/dev/null` must be a working char device
* Free disk: ~10 GB during build, ~1.5 GB for the final ISO
* Fast Arch mirror: lysator.se (~5 MB/s) — embedded in the profile, no host config needed

## One-time sudo setup

The build invokes `mkarchiso` with `sudo`. To avoid password prompts during the
build, install a NOPASSWD rule for the binary only:

```bash
echo "deadmafia ALL=(ALL) NOPASSWD: /usr/bin/mkarchiso" | sudo tee /etc/sudoers.d/mkarchiso-nopasswd
sudo chmod 0440 /etc/sudoers.d/mkarchiso-nopasswd
sudo visudo -c
```

## The hacker arsenal

Damascus ships a **lean** live ISO on purpose — fast boot, small image, small
trust surface. The base image carries only the always-reach-for tools (`nmap`,
`tcpdump`, `socat`, `openbsd-netcat`, `proxychains-ng`, `macchanger`, `python`,
`base-devel`, etc.). The heavier pentest toolkit is pulled **on demand** with
`damascus-arsenal`, which installs only from the official Arch repos (no AUR,
no third-party repos — everything is signed by Arch).

```bash
damascus-arsenal list              # show all tool groups + packages
damascus-arsenal show wireless     # inspect one group
damascus-arsenal search ghidra     # which group has a tool?
damascus-arsenal install recon web # install one or more groups
damascus-arsenal install all       # the whole arsenal
```

Tool groups: `recon web exploit cracking wireless sniffing reversing
forensics crypto anon dev` (86 official packages total). The script lives at
`iso/damascus/airootfs/usr/local/bin/damascus-arsenal`.

A handful of well-known tools are AUR-only and intentionally excluded under the
official-repos-only policy (e.g. `ffuf`, `feroxbuster`, `wfuzz`, `seclists`,
`crunch`, `netexec`, `responder`, `volatility`). Install those with an AUR
helper if you need them.

## Layout

```
/home/deadmafia/Documents/damascus/
├── docs/                  documentation
│   └── README.md          this file
├── assets/                build/test scripts + ISO output
│   ├── build.sh           run mkarchiso end-to-end
│   ├── qemu-test.sh       boot ISO with QEMU (GUI)
│   ├── boot-test.sh       headless boot capture
│   └── iso-out/           where the final ISO lands
├── iso/
│   └── damascus/          archiso profile (customized)
│       ├── profiledef.sh  iso_name=damascus, install_dir=damascus
│       ├── packages.x86_64  lean live package list (base + net + baseline tools)
│       ├── pacman.conf    pacman config with fast mirrors embedded
│       ├── airootfs/      live filesystem overlay
│       │   ├── etc/
│       │   │   ├── os-release   NAME="Damascus OS" ID=damascus
│       │   │   ├── issue        pre-login banner
│       │   │   ├── motd         post-login ASCII art + arsenal hint
│       │   │   ├── locale.conf  LANG=C.UTF-8
│       │   │   └── shadow       root with no password
│       │   └── usr/local/bin/
│       │       └── damascus-arsenal  on-demand pentest installer
│       ├── grub/          GRUB bootloader config
│       ├── syslinux/      ISOLINUX/SYSLINUX bootloader config
│       └── efiboot/       UEFI shim + grub binaries
├── kernel/                archlinux/linux.git (vanilla, depth=1 — reference only)
├── packages/
│   ├── svntogit-packages/   2,540 PKGBUILDs (core+extra)
│   └── svntogit-community/  9,426 PKGBUILDs (community)
└── build-system/          source for archiso, devtools, pacman, etc.
```

## Source repos cloned (depth=1)

| Path                                  | Origin                                          |
|---------------------------------------|-------------------------------------------------|
| `kernel/`                             | `https://github.com/archlinux/linux.git`        |
| `packages/svntogit-packages/`         | `https://github.com/archlinux/svntogit-packages`|
| `packages/svntogit-community/`        | `https://github.com/archlinux/svntogit-community`|
| `build-system/archiso/`               | `https://github.com/archlinux/archiso`          |
| `build-system/devtools/`              | `https://github.com/archlinux/devtools`         |
| `build-system/mkinitcpio/`            | `https://github.com/archlinux/mkinitcpio`       |
| `build-system/arch-install-scripts/`  | `https://github.com/archlinux/arch-install-scripts`|
| `build-system/pacman/`                | `https://gitlab.archlinux.org/pacman/pacman`    |
| `build-system/pacman-contrib/`        | `https://github.com/archlinux/pacman-contrib`   |

## Identity

```
NAME="Damascus OS"
ID=damascus
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="0;36"
```

## After the first prototype works

1. Customize packages.x86_64 — drop what you don't need, add what you want
2. Add user accounts / autologin in airootfs/etc/
3. Modify kernel — clone `kernel/` if you want a custom kernel
4. Replace or shrink bootloader configs (grub/, syslinux/)
5. Add a custom repo file under airootfs/etc/pacman.conf.d/
6. Build your own PKGBUILDs into packages/ and use them via [custom] repo
