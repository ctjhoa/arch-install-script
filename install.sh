#!/bin/bash

# see http://redsymbol.net/articles/unofficial-bash-strict-mode/
# To silent an error || true
set -euo pipefail
IFS=$'\n\t' 

if [ "${1:-}" = "--debug" ] || [ "${1:-}" = "-d" ]; then
	set -x
fi

###############################################################################
# Questions part
###############################################################################

if [ $EUID -ne 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "
You're about to install my basic user session.
Require a xf86-video driver, an internet connection, base and base-devel packages.
Please enter 'yes' to confirm:
"
read yes

# Confirm video driver
if [ "$yes" != "yes" ]; then
    echo "Please install a xf86-video driver"
	pacman -Ss xf86-video
    exit 1
fi

# Check internet connection
if ! [ "$(ping -c 1 8.8.8.8)" ]; then
    echo "Please check your internet connection"
    exit 1
fi

if ! source install.conf; then
	echo "
	Virtual box install?
	Please enter 'yes' to confirm, 'no' to reject:
	"
	read vbox_install

	echo "Please enter hostname:"
	read hostname

	echo "Please enter username:"
	read username

	echo "Please enter password:"
	read -s password

	echo "Please repeat password:"
	read -s password2

	# Check both passwords match
	if [ "$password" != "$password2" ]; then
	    echo "Passwords do not match"
	    exit 1
	fi

	echo "Please enter full name:"
	read fullname

	echo "Please enter email:"
	read email
fi

if [ -z "$proxy" ]; then
	alias sudo="sudo -u $username "
else
	export http_proxy=$proxy
	export https_proxy=$http_proxy
	export ftp_proxy=$http_proxy
	alias sudo="sudo -u $username env http_proxy=$http_proxy https_proxy=$https_proxy ftp_proxy=$ftp_proxy "
fi


# Save current pwd
pwd=`pwd`

echo "
###############################################################################
# Pacman conf
###############################################################################
"
# Rankmirrors
pacman --noconfirm -S reflector
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -c France -f 10 --save /etc/pacman.d/mirrorlist

sed -i 's/^#Color/Color/' /etc/pacman.conf

echo "
###############################################################################
# Install part
###############################################################################
"
# Sync
pacman --noconfirm -Syu

array=()

# Install X essentials
array+=( xorg-server xorg-server-utils xorg-xinit dbus )

# Install admin tools
array+=( git zsh grml-zsh-config tmux reflector openssh )

# Install window manager
array+=( awesome slock )

# Install dev tools
array+=( vim emacs )

# Install requirements for pacaur
array+=( sudo expac )

# Install audio
array+=( alsa-utils )

# Install useful apps
array+=( keepass vlc gimp firefox scribus rtorrent )
array+=( libreoffice-writer libreoffice-calc libreoffice-impress )

# Install fonts
array+=( ttf-freefont ttf-liberation ttf-dejavu )
array+=( adobe-source-serif-pro-fonts )
array+=( dina-font terminus-font tamsyn-font artwiz-fonts )

pacman --noconfirm --needed -S  ${array[@]}

chsh -s /bin/zsh

# Install infinality bundle
if ! grep --quiet infinality-bundle /etc/pacman.conf; then
echo '
[infinality-bundle]
Server = http://bohoomil.com/repo/$arch' >> /etc/pacman.conf
pacman-key -r 962DDE58
pacman-key --lsign-key 962DDE58
pacman --noconfirm -Syu
pacman --noconfirm -Rdd cairo fontconfig freetype2
pacman --noconfirm -S infinality-bundle
fi

# Install vbox guest addition
if [ "$vbox_install" != "yes" ]; then
pacman --noconfirm -S virtualbox-guest-modules
echo "vboxguest
vboxsf
vboxvideo
" > /etc/modules-load.d/virtualbox.conf
fi

echo "
###############################################################################
# Systemd part
###############################################################################
"
# Generate locales
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Set timezone
timedatectl --no-ask-password set-timezone Europe/Paris

# Set NTP clock
timedatectl --no-ask-password set-ntp 1

# Set locale
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_COLLATE="C" LC_TIME="fr_FR.UTF-8"

# Set keymaps
localectl --no-ask-password set-keymap us
localectl --no-ask-password set-x11-keymap us

# Hostname
hostnamectl --no-ask-password set-hostname $hostname

# DHCP
systemctl --no-ask-password enable dhcpcd

# SSH
systemctl --no-ask-password enable sshd

echo "
###############################################################################
# Modules
###############################################################################
"
# Disable PC speaker beep
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

echo "
###############################################################################
# User part
###############################################################################
"
# Create user with home
if ! id -u $username; then
	useradd -m --groups users,wheel $username
	echo "$username:$password" | chpasswd
	chsh -s /bin/zsh $username
fi

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Install pacaur
if ! command -v cower; then
	cd /tmp
	curl -OL http://aur.archlinux.org/packages/co/cower/cower.tar.gz
	tar -xzf cower.tar.gz
	chown $username cower -R
	cd cower
	sudo makepkg -s
	pacman --noconfirm -U *.tar.xz
fi

if ! command -v pacaur; then
	cd /tmp
	cower -d pacaur
	chown $username pacaur -R
	cd pacaur
	sudo makepkg -s
	pacman --noconfirm -U *.tar.xz
fi

array=()

# Install utilities
array+=( compton-git )

# Install basic fonts
array+=( ttf-ms-fonts ttf-vista-fonts ttf-google-fonts-git ttf-chromeos-fonts )

# Install programming fonts
array+=( ttf-monaco ttf-inconsolata-g ttf-migu ttf-ricty ttf-anonymous-pro ttf-clear-sans )

# Install bitmap fonts
array+=( stlarch_font stlarch_icons termsyn )

# Install theme
array+=( numix-themes moka-icons-git )

# Install others
array+=( libreoffice-extension-languagetool )

sudo pacaur --noconfirm --noedit -S ${array[@]}

echo "
###############################################################################
# Git config part
###############################################################################
"

# Go home
cd `eval echo ~$username`

echo "[user]
	name = $fullname
	email = $email
[core]
	editor = vim
[alias]
	st = status
	ci = commit
	co = checkout
	br = branch -vv
	sl = log --graph --pretty=oneline --abbrev-commit --decorate
	up = pull --rebase
[color]
	branch = auto
	diff = auto
	interactive = auto
	status = auto" > .gitconfig

echo "
###############################################################################
# My git repos
###############################################################################
"

# Dotfiles
rm -rf dotfiles
sudo git clone http://github.com/ctjhoa/dotfiles.git
sudo dotfiles/install.sh

# Dwm (Dynamic Window Manager - suckless)
rm -rf dwm
sudo git clone http://github.com/ctjhoa/dwm.git
sudo dwm/install.sh

# St (Simple terminal - suckless)
rm -rf st
sudo git clone http://github.com/ctjhoa/st.git
sudo st/install.sh

echo "
###############################################################################
# Cleaning
###############################################################################
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Clean orphans pkg
if [[ ! -n $(pacman -Qdt) ]]; then
	echo "No orphans to remove."
else
	pacman -Rns $(pacman -Qdtq)
fi

# Replace in the same state
cd $pwd
echo "
###############################################################################
# Done
###############################################################################
"
