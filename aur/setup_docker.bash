#! /bin/bash

pacman --noconfirm -S archlinux-keyring
pacman --noconfirm -S base-devel git
pacman --noconfirm -Syu

useradd notroot
echo "notroot ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/notroot

# Wrapper function since makepkg cannot be run by root
makepkg_func()
{
    var="$@"
    sudo -u notroot -- sh -c "makepkg $var"
}
alias makepkg="makepkg_func"

makepkg --syncdeps --noconfirm
