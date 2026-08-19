#!/usr/bin/env bash
set -euo pipefail
if [ "$EUID" -ne 0 ]; then
  echo "err: root required" >&2
  exit 1
fi
lsblk -d -n -o NAME,SIZE,MODEL | grep -v "loop"
read -rp "disk: " DISK </dev/tty
[[ "$DISK" != /dev/* ]] && DISK="/dev/$DISK"
if [ ! -b "$DISK" ]; then
  echo "err: invalid disk" >&2
  exit 1
fi
read -rp "wipe $DISK? (y/n): " CONFIRM </dev/tty
if [[ "$CONFIRM" != [yY] ]]; then
  exit 0
fi
wipefs -a "$DISK"
parted --script "$DISK" mklabel gpt
parted --script "$DISK" mkpart ESP fat32 1MiB 1024MiB
parted --script "$DISK" set 1 esp on
parted --script "$DISK" mkpart primary ext4 1024MiB 100%
if [[ "$DISK" =~ nvme ]] || [[ "$DISK" =~ mmcblk ]]; then
  BOOT_PART="${DISK}p1"
  ROOT_PART="${DISK}p2"
else
  BOOT_PART="${DISK}1"
  ROOT_PART="${DISK}2"
fi
partprobe "$DISK"
udevadm settle
wipefs -a "$BOOT_PART"
wipefs -a "$ROOT_PART"
mkfs.fat -F32 -n boot "$BOOT_PART"
mkfs.ext4 -F -L nixos "$ROOT_PART"
udevadm settle
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$BOOT_PART" /mnt/boot
mkdir -p /mnt/etc/nixos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -r "$SCRIPT_DIR/." /mnt/etc/nixos/
nixos-generate-config --root /mnt
cd /mnt/etc/nixos
rm -f "/mnt/etc/nixos/$(basename "$0")"
if [ ! -d .git ]; then
  git init
fi
git config user.name "installer"
git config user.email "installer@field"
git add -A
nixos-install --flake /mnt/etc/nixos#stille --no-root-passwd
sync
read -rp "reboot? (y/n): " REBOOT </dev/tty
if [[ "$REBOOT" == [yY] ]]; then
  reboot
fi
