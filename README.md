createarchusb
=============

**Scripts for creating persistent bootable Archlinux installations on USB drives.**

# Usage:
## Choose the right USB drive
Make sure you pick a fast USB drive with low access time. I recommend SanDisk Cruzer Blades. USB 3.0 pen drives usually arent't faster than USB 2.0 ones.
For some reason, some GPU drivers (especially nouveau) may not work on cheap drives. Some computers (especially Macs) don't boot from USB 3.0 drives and some don't support booting from USB 3.0 ports. I tested the script with many different drives, SanDisk worked best, followed by ADATA and Transcend. DataTravelers and SONY drives are OK while Intenso and hama drives didn't work at all.

## Configure the script to your needs
Use this line to configure the system's hostname:

	NAME="caglux"

Use this line to configure your timezone:

	TIMEZONE=/usr/share/zoneinfo/Europe/Berlin

Choose the locale to be used in /etc/locale.gen here:

	LOCALE="de_DE.UTF-8 UTF-8"

Choose the locale to be used with the localectl command here:

	LOCALE_LCTRL="de_DE.utf8"

Choose your preferred keymap:

	KEYMAP="de"

One non-root user with sudo access will be created. Choose its username:

	USERNAME="cag"

Choose the full name of the user, it will e.g. be displayed in gdm / gnome:

	USER_FULLNAME="Computer AG"

The default configuration includes the Cinnamon desktop environment, SLiM, NetworkManager, Chromium, various open-source Video drivers, VLC, L&ouml;ve2d, AVR tools and multiple utilities. You can edit these in the following lines.
However, I have found that Cinnamon seems to be the best desktop environment for USB drives while KDE is barely usable. XFCE and GNOME are usable, but not exactly fast.

The password for the users can be chosen later.

## Decide which architecture you want to use (32bit / 64 bit have been tested)

If you run the script on a 64-bit Archlinux system, the system on the USB drive will also be 64-bit. Running it on a 32-bit system generates a 32-bit persistent system.
Only 64-bit USB drives will also boot on Macs, as they require a 64-bit EFI bootloader installation.

## Install dependencies
You have to run the script from an Archlinux system and the following packages installed: arch-install-scripts dosfstools gptfdisk
Install them via

	sudo pacman -Sy arch-install-scripts dosfstools gptfdisk

## Generate the bootable system
Call the script with root permissions on an Archlinux system.

	sudo ./createarchusb-cinnamon.sh

It will then ask you what device to install the system on. Enter e.g.

	/dev/sdc

**The script will erase ALL DATA on the device. So make sure you get this right!**

In the end, the script will ask you to enter passwords for the root user and the normal user.

## Reboot
Reboot the system and select the USB drive in the boot menu. The localization will be applied during the first boot. You should have a persistent mobile Archlinux installation by now!

## Get help if something went wrong
If the script didn't work for you, file an issue on GitHub for this repo. You can also send pull requests with other scripts for your configuration.
