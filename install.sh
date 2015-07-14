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

if [ -z ${proxy:+x} ]; then
	alias sudo="sudo -i -u $username "
else
	export http_proxy=$proxy
	export https_proxy=$http_proxy
	export ftp_proxy=$http_proxy
	alias sudo="sudo -i -u $username env http_proxy=$http_proxy https_proxy=$https_proxy ftp_proxy=$ftp_proxy "
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
reflector -c France -f 10 -p http --save /etc/pacman.d/mirrorlist

sed -i 's/^#Color/Color/' /etc/pacman.conf

# keyring conf
pacman --noconfirm -Syu haveged
systemctl --no-ask-password start haveged
systemctl --no-ask-password enable haveged

echo "
###############################################################################
# Install part
###############################################################################
"

pacman_packages=()

# Install X essentials
pacman_packages+=( xorg-server xorg-server-utils xorg-xinit dbus xsel )

# Install admin tools
pacman_packages+=( git zsh grml-zsh-config tmux openssh ntfs-3g )

# Install window manager
pacman_packages+=( awesome slock dmenu )

# Install dev tools
pacman_packages+=( vim emacs stow )

# Work tools
pacman_packages+=( nodejs npm )

# Install requirements for pacaur
pacman_packages+=( sudo expac )

# Install audio
pacman_packages+=( alsa-utils )

# Install useful apps
pacman_packages+=( keepass vlc gimp firefox scribus rtorrent weechat scrot feh )
pacman_packages+=( libreoffice-fresh )

# Install infinality bundle
if ! grep --quiet infinality-bundle /etc/pacman.conf; then
echo '
[infinality-bundle]
Server = http://bohoomil.com/repo/$arch

[infinality-bundle-fonts]
Server = http://bohoomil.com/repo/fonts' >> /etc/pacman.conf
pacman-key -r 962DDE58
pacman-key --lsign-key 962DDE58
pacman --noconfirm -Syu
pacman --noconfirm -Rdd cairo fontconfig freetype2
pacman --noconfirm -S infinality-bundle
fi

pacman --noconfirm --needed -S  ${pacman_packages[@]}

chsh -s /bin/zsh

# Install vbox guest addition
if [ "$vbox_install" == "yes" ]; then
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
systemctl --no-ask-password start dhcpcd

# SSH
systemctl --no-ask-password enable sshd
systemctl --no-ask-password start sshd

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

function install_aur {
	for ARG in "$@"
	do
		if ! command -v $ARG; then
			cd /tmp
			curl -OL http://aur.archlinux.org/packages/${ARG:0:2}/${ARG}/${ARG}.tar.gz
			tar -xzf ${ARG}.tar.gz
			chown $username $ARG -R
			cd $ARG
			makepkg -s
			pacman --noconfirm -U *.tar.xz
		fi
	done
}

# Install pacaur
ssh $username@localhost "$(typeset -f); install_aur cower pacaur"

#if ! command -v cower; then
#	cd /tmp
#	curl -OL http://aur.archlinux.org/packages/co/cower/cower.tar.gz
#	tar -xzf cower.tar.gz
#	chown $username cower -R
#	cd cower
#	sudo makepkg -s
#	pacman --noconfirm -U *.tar.xz
#fi
#
#if ! command -v pacaur; then
#	cd /tmp
#	cower -d pacaur
#	chown $username pacaur -R
#	cd pacaur
#	sudo makepkg -s
#	pacman --noconfirm -U *.tar.xz
#fi

aur_packages=()

# Install utilities
aur_packages+=( compton-git redshift-minimal )

# Work tools
aur_packages+=( rust-nightly-bin editorconfig-core-c )

# Install basic fonts
aur_packages+=( ibfonts-meta-base ibfonts-meta-extended )
aur_packages+=( ttf-clear-sans-ibx ttf-consola-mono-ibx ttf-lato-ibx ttf-paratype-ibx ttf-roboto-ibx otf-source-code-pro-ibx otf-source-sans-pro-ibx otf-source-serif-pro-ibx )

# Install programming fonts
aur_packages+=( ttf-monaco ttf-anonymous-pro ttf-inconsolata-g ttf-migu ttf-ricty )

# Install bitmap fonts
aur_packages+=( dina-font terminus-font tamsyn-font artwiz-fonts )
aur_packages+=( stlarch_font stlarch_icons termsyn )

# Install theme
aur_packages+=( numix-themes moka-icons-git )

# Install others
aur_packages+=( libreoffice-extension-languagetool )

sudo pacaur --noconfirm --noedit -S ${aur_packages[@]}


npm_packages=()

npm_packages+=( grunt gulp ember-cli tern bower )

sudo npm install -g ${npm_packages[@]}

echo "
###############################################################################
# My git repos
###############################################################################
"

# Dotfiles
rm -rf dotfiles
sudo git clone https://github.com/ctjhoa/dotfiles.git
sudo dotfiles/install.sh

# Dwm (Dynamic Window Manager - suckless)
rm -rf dwm
sudo git clone https://github.com/ctjhoa/dwm.git
sudo dwm/install.sh

# St (Simple terminal - suckless)
rm -rf st
sudo git clone https://github.com/ctjhoa/st.git
sudo st/install.sh

echo "
###############################################################################
# Cleaning
###############################################################################
"
unalias sudo
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
