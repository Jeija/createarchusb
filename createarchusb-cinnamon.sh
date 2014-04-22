#!/bin/bash

# Dependencies: arch-install-scripts dosfstools gptfdisk

######################
###### Settings ######
######################
NAME="caglux" # Label as well as hostname
TIMEZONE=/usr/share/zoneinfo/Europe/Berlin
LOCALE="de_DE.UTF-8 UTF-8"
LOCALE_LCTRL="de_DE.utf8"
KEYMAP="de"
USERNAME="cag"
USER_FULLNAME="Computer AG"

ADD_PACKAGES_XORG="xorg-server xorg-xinit xorg-utils xorg-server-utils"
ADD_PACKAGES_DRIVERS="xf86-input-synaptics"
ADD_PACKAGES_VID="xf86-video-nouveau xf86-video-vesa mesa xf86-video-ati xf86-video-intel xf86-video-nv"
ADD_PACKAGES_ENV="cinnamon slim networkmanager archlinux-themes-slim"
ADD_PACAKGES_APP="chromium avr-gcc avrdude avr-libc make gedit bash-completion file-roller p7zip openssh gptfdisk arch-install-scripts vlc dosfstools gnome-terminal network-manager-applet love python2-pygame freeglut glew bc"
ADD_PACKAGES_REP="arch-install-scripts dosfstools gptfdisk"
SUDO_CONFIG="%wheel ALL=(ALL) NOPASSWD: ALL"
enable_desktopmanager="systemctl enable slim" 
enable_networkmanager="systemctl enable NetworkManager.service"
ROOT_UUID=$(uuidgen)

#######################
###### Resources ######
#######################
fstab="# \n
# /etc/fstab: static file system information\n
#\n
# <file system>	<dir>	<type>	<options>	<dump>	<pass>\n
UUID=$ROOT_UUID / ext4 rw,relatime,data=ordered 0 1"

xinitrc="#!/bin/sh\nif [ -d /etc/X11/xinit/xinitrc.d ]; then\n  for f in /etc/X11/xinit/xinitrc.d/*; do\n    [ -x "$f" ] && . "$f"\n  done\n  unset f\nfi\n\nexec cinnamon-session"

gummiboot_entry="title Arch Linux\nlinux /vmlinuz-linux\ninitrd /initramfs-linux.img\noptions root=UUID=$ROOT_UUID rw"

archlinuxfr="[archlinuxfr]\nSigLevel = Optional TrustAll\nServer = http://repo.archlinux.fr/\$arch"

ADD_PACKAGES_DEF="base-devel syslinux sudo wget gummiboot"
PACKAGES="base $ADD_PACKAGES_DEF $ADD_PACKAGES_XORG $ADD_PACKAGES_DRIVERS $ADD_PACKAGES_VID $ADD_PACKAGES_ENV $ADD_PACAKGES_APP $ADD_PACKAGES_REP"

chr="arch-chroot /mnt/$ROOT_UUID "

locale_service="[Unit]\nDescription=Sets up locale\n\n[Service]\nExecStart=/opt/locale_script.sh\n[Install]\nWantedBy=multi-user.target"

locale_script="#!/bin/sh\nlocalectl set-locale LANG=$LOCALE_LCTRL\nlocalectl set-keymap $KEYMAP\nlocalectl set-x11-keymap $KEYMAP\nsystemctl disable caglux_locale"

#########################
###### Preparation ######
#########################

# Abort if not run as root
if [ $(id -u) -ne 0 ]
then
   echo "This script must be run as root. Aborting."
   exit 1
fi

# Exit if something fails:
set -e

# Show available disks and let the user choose one
fdisk -l
echo "Enter disk /dev/sdX and press [ENTER]: "
read DISK

# Check if user input is sane
if ! [ -b "$DISK" ]
then
	echo "$DISK is no valid block device."
	exit 1
fi

echo "This script will delete everything on $DISK. Are you sure?"
echo "Press [ENTER] to continue or abort with [Ctrl]+[C]"
read -p "$*"

########################
###### Formatting ######
########################

# Unmount and partition the drive
umount $DISK? || /bin/true # unmount any /dev/sdXY
echo "Partitioning...";
(echo g; echo n; echo 1; echo ; echo +512M; echo t; echo 1; echo n; echo 2; echo ; echo; echo w) | sudo fdisk $DISK

# EFI Partition
EFIPARTNUM="1"
EFIPARTITION="$DISK$EFIPARTNUM"
echo "Formatting $EFIPARTITION"
mkfs.vfat -F32 $EFIPARTITION

# Format /dev/sdX1
PARTNUM="2"
PARTITION="$DISK$PARTNUM"
echo "Formatting $PARTITION"
mkfs.ext4 $PARTITION
#e2label $PARTITION $NAME
tune2fs $PARTITION -U $ROOT_UUID

##########################
###### Installation ######
##########################

# Create folder to mount the drive
mkdir /mnt/$ROOT_UUID

# Mount /dev/sdX1 at /mnt/$ROOT_UUID
mount $PARTITION /mnt/$ROOT_UUID
mkdir /mnt/$ROOT_UUID/boot
mount $EFIPARTITION /mnt/$ROOT_UUID/boot

# Install base system
pacstrap /mnt/$ROOT_UUID $PACKAGES

###########################
###### Configuration ######
###########################

# Write /etc/fstab
echo -e $fstab > /mnt/$ROOT_UUID/etc/fstab
echo $NAME > /mnt/$ROOT_UUID/etc/hostname

# Slim Configuration
sed -i "s/current_theme.*/current_theme archlinux-soft-grey/" /mnt/$ROOT_UUID/etc/slim.conf
sed -i "s/#default_user.*/default_user cag/" /mnt/$ROOT_UUID/etc/slim.conf

# Chroot into the system
$chr ln -s $TIMEZONE /etc/localtime
$chr mkinitcpio -p linux
$chr syslinux-install_update -i -m
sleep 2
umount /mnt/$ROOT_UUID/dev || /bin/true
sed -i "s/APPEND root=.*/APPEND root=UUID=$ROOT_UUID rw/g" /mnt/$ROOT_UUID/boot/syslinux/syslinux.cfg
$chr $enable_desktopmanager
$chr $enable_networkmanager

# Localization: Locales will actually be set during the first boot by a script
sed -i "/${LOCALE}/ s/#*//" /mnt/$ROOT_UUID/etc/locale.gen
$chr locale-gen
echo -e $locale_script > /mnt/$ROOT_UUID/opt/locale_script.sh
$chr chmod 777 /opt/locale_script.sh
echo -e $locale_service > /mnt/$ROOT_UUID/etc/systemd/system/caglux_locale.service
$chr systemctl enable caglux_locale

# Install MBR
sgdisk $DISK --attributes=1:set:2
dd bs=440 conv=notrunc count=1 if=/mnt/$ROOT_UUID/usr/lib/syslinux/bios/gptmbr.bin of=$DISK

####################
###### Yaourt ######
####################

echo -e $archlinuxfr >> /mnt/$ROOT_UUID/etc/pacman.conf
$chr pacman -Sy --noconfirm yaourt

######################
###### DVSwitch ######
######################
#
#$chr wget http://mesecons.net/dvswitch_bundle.tar.gz -P /opt
#$chr tar -xvf /opt/dvswitch_bundle.tar.gz -C /opt
#$chr /opt/dvswitch_bundle/build.sh
#$chr /opt/dvswitch_bundle/build.sh
#$chr make install -C /opt/dvswitch_bundle/dvswitch/

#############################
###### Users/Passwords ######
#############################
sed -i "/${SUDO_CONFIG}/ s/# *//" /mnt/$ROOT_UUID/etc/sudoers
$chr useradd -G "wheel" -m -k /etc/skel $USERNAME
# add .xinitrc
echo -e $xinitrc > /mnt/$ROOT_UUID/home/cag/.xinitrc
$chr chfn -f "$USER_FULLNAME" $USERNAME
echo "Root Password:"
$chr passwd
echo "User Password:"
$chr passwd $USERNAME

#####################################
##### Copy Itself - Repliaction #####
#####################################

cp $0 /mnt/$ROOT_UUID/home/$USERNAME/

####################### Last thing, as afterwards
###### EFI Stuff ###### we cannot chroot anymore because
####################### /mnt/$ROOT_UUID/sys has been changed

# EFI Stuff
$chr gummiboot install
echo -e $gummiboot_entry > /mnt/$ROOT_UUID/boot/loader/entries/arch.conf
sleep 5

##############################
###### Unmount / Finish ######
##############################
umount -R /mnt/$ROOT_UUID
rmdir /mnt/$ROOT_UUID
echo "USB Archlinux Creation script finished."
