# Packaging for ArchLinux/Manjaro

This repository contains the code necessary to build packages for ArchLinux/Manjaro (and particularly AUR).

## Huawei-HiQ on AUR

All the Huawei-HiQ packages can be found on AUR: https://aur.archlinux.org/packages/

## Environment setup

Make sure that you have all the basic dependencies instaslled on your system

 - archlinux-keyring
 - base-devel

You can install them using a command similar to this one

	sudo pacman -Syu
	sudo pacman -S archlinux-keyring base-devel

## Build the package

Simply run `makepkg` from within the folder of the package you would like to build

	makepkg --syncdeps --noconfirm

The `--syncdeps --noconfirm` options will tell `makepkg` to try to automatically install the dependencies required to build the package on your system if they are not already installed. In some cases, this command might fail, e.g. in case one of the dependencies is on AUR. If that happens, you will have to manually install the dependency, e.g. using `yay`

	yay install python3-hiq-projectq
