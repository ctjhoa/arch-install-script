arch-install-script
===================

My archlinux install script

## Usage

```bash
$ git clone https://github.com/ctjhoa/arch-install-script
$ cd arch-install-script
$ ./install.sh
```
NOTE: You can automate config with `cp install.conf.sample install.conf` then edit it

## Additional config

- Touchpad

```
# /etc/X11/xorg.conf.d/30-touchpad.conf

Section "InputClass"
  Identifier "Elantech Touchpad"
  Driver "libinput"
  MatchIsTouchpad "on"
  Option "DisableWhileTyping" "on"
  Option "MiddleEmulation" "on"
  Option "Tapping" "on"
  Option "TappingButtonMap" "lmr"
EndSection
```

## Prerequisite

### Flash arch on a USB key

https://wiki.archlinux.org/index.php/USB_flash_installation_media

### Install arch

The following is just a simplified version of arch installation guide for my personal usage.

Full guide is here https://wiki.archlinux.org/index.php/installation_guide

1. `loadkeys fr`
2. `timedatectl set-ntp true`
3. `wifi-menu -o`
4. `fdisk /dev/sda`
    1. New `512M` `EFI System` -> `mkfs.fat -F32 /dev/sda1`
    2. New `2G` `Linux Swap` -> `mkswap /dev/sda2 && swapon /dev/sda2`
    3. New `Linux filesystem` -> `mkfs.ext4 /dev/sda3`
5. `mount /dev/sda3 /mnt`
6. `mount /dev/sda1 /mnt/boot`
7. `pacstrap /mnt base base-devel dialog wpa_supplicant intel-ucode git mesa`
8. `genfstab -U /mnt >> /mnt/etc/fstab`
9. `arch-chroot /mnt`
10. `ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime`
11. `hwclock --systohc # hardware suppose to be in UTC`
12. `passwd`
13. `bootctl --path=/boot install`
14. Configure systemd-boot
```
# esp/loader/loader.conf
------------------------
default  arch
timeout  4
editor   no
```
```
# esp/loader/entries/arch.conf
------------------------------
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=${blkid -s PARTUUID -o value /dev/sda3} rw
```
15. Set the keyboard layout in console
```
# /etc/vconsole.conf
-------------------
KEYMAP=fr
```
16. `umount -R /mnt` and `reboot`
17. Install arch-install-script
