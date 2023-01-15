#!/bin/bash

echo "
###############################################################################
# My git repos
###############################################################################
"

# Dotfiles
git clone --recursive git@github.com:ctjhoa/dotfiles.git || git clone --recursive https://github.com/ctjhoa/dotfiles.git
cd dotfiles
./install.sh
cd -

# St (Simple terminal - suckless)
git clone git@github.com:ctjhoa/st.git || git clone https://github.com/ctjhoa/st.git
cd st
./install.sh
cd -

# Dwm (Dynamic Window Manager - suckless)
git clone git@github.com:ctjhoa/dotfiles.git || git clone https://github.com/ctjhoa/dwm.git
cd dwm
./install.sh
cd -

echo "
###############################################################################
# PGP
###############################################################################
"
# Create gpg db
gpg --list-keys

# Packages signature checking
echo "keyserver-options auto-key-retrieve" >> .gnupg/gpg.conf
echo "keyserver hkp://pgp.mit.edu" >> .gnupg/gpg.conf

echo "
###############################################################################
# User packages
###############################################################################
"

function install_aur {
	for ARG in "$@"
	do
		if ! command -v $ARG; then
			git clone https://aur.archlinux.org/${ARG}.git
			cd $ARG
			makepkg -sri --noconfirm
		fi
	done
}

# Install AUR packages
install_aur yay libreoffice-extension-languagetool

# Install more fonts
# ttf-lato ttf-paratype ttf-clear-sans ttf-fira-mono ttf-monaco
