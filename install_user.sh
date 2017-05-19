#!/bin/bash

echo "
###############################################################################
# My git repos
###############################################################################
"

# Dotfiles
git clone git@github.com:ctjhoa/dotfiles.git || git clone https://github.com/ctjhoa/dotfiles.git
cd dotfiles
./install.sh
cd -

# Dwm (Dynamic Window Manager - suckless)
git clone git@github.com:ctjhoa/dotfiles.git || git clone https://github.com/ctjhoa/dwm.git
cd dwm
./install.sh
cd -

# St (Simple terminal - suckless)
git clone git@github.com:ctjhoa/st.git || git clone https://github.com/ctjhoa/st.git
cd st
./install.sh
cd -

echo "
###############################################################################
# PGP
###############################################################################
"

# Packages signature checking
sed -i 's|^#keyserver-options auto-key-retrieve|keyserver-options auto-key-retrieve|' .gnupg/gpg.conf
sed -i 's|^keyserver hkp://keys.gnupg.net|#keyserver hkp://keys.gnupg.net|' .gnupg/gpg.conf
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

# Install pacaur
install_aur cower pacaur

aur_packages=()

# Install utilities
aur_packages+=( compton-git redshift-minimal )

# Work tools
aur_packages+=( editorconfig-core-c )

# Install more fonts
# aur_packages+=( ttf-lato ttf-paratype ttf-clear-sans ttf-fira-mono ttf-monaco )
aur_packages+=( stlarch_font stlarch_icons )

# Install theme
aur_packages+=( numix-themes moka-icon-theme-git )

# Install others
aur_packages+=( libreoffice-extension-languagetool )

pacaur -S --noconfirm --noedit --needed ${aur_packages[@]}
