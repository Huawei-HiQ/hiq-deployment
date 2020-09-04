# Packaging for Debian/Ubuntu

This repository contains the code necessary to build DEB source and binary packages.

## Environment setup

 Make sure that you have all the basic dependencies installed on your system:

  - build-essential
  - devscripts
  - lintian
  - debhelper
  - dh-make
  - dh-python
  - fakeroot

You can install them using a command similar to this one

	sudo apt install -y build-essential devscripts lintian debhelper dh-make dh-python fakeroot

### Automated setup

The easiest way to setup your environment to build one of the DEB packages is to use the `setup.bash` BASH script. You will find below its help message for convenience:

	Usage:
	   setup.bash [options] dest_dir

	Options:
	  -h,--help     Show this help message and exit
	  --projectq    Select HiQ-ProjectQ
	  --circuit     Select HiQ-Circuit (HiQSimulator)

	Example calls:
	./setup.bash --projectq /path/to/dst_dir
	./setup.bash --circuit /path/to/dst_dir

Note that you will need to have `pip` installed on your system for this script to work. You can install it using a command similar to

	sudo apt install -y python3-pip

### Manual setup

In order to properly setup an environment to build either the source or binary DEB packages, you first need to download a valid release tarball from the package you require. Then unpack the tarball and copy the template `*-debian` folder within the unpacked source directory.

#### debian/changelog

You need to generate the `debian/changelog` file. You may try to use the function `gen_changelog` defined in `scripts/file_generation.bash`. An example is provided below

	hiq-projectq (0.6.5) unstable; urgency=medium

	  * Blabla

	 -- John Doe <john@example.com>  Mon, 01 Jan 2020 00:00:00 +0000

#### debian/compat

You need to generate the `debian/compat` file. You may try to use the function `gen_compat` defined in `scripts/file_generation.bash`. An example is provided below

	11

#### debian/watch

You need to generate the `debian/watch` file. You may try to use the function `gen_watch` defined in `scripts/file_generation.bash`. An example is provided below

	version=4
	https://pypi.debian.net/hiq-projectq/hiq-projectq-(.+)\.(?:zip|tgz|tbz|txz|(?:tar\.(?:gz|bz2|xz)))

### GPG Key

In order to submit your package to a repository, you might need to sign it using a GPG key. In order to facilitate the building process, you can add this line to the `~/devscripts` file (create it if it does not already exist)

	DEBSIGN_KEYID="key-id"

where you would replace `key-id` with your own GPG key identifier.

## Building a DEB package

### Automated build (Ubuntu PPA)

The easiest way to build a source package and submit it to a PPA is to use the `ubuntu_ppa_upload.bash` script. Its help message is below for convenience

	Usage:
	   ubuntu_ppa_upload.bash [options] src_dir

	Options:
	  -h,--help          Show this help message and exit
	  -n [rev_num]       (optional) Revision number for ubuntu version number
						 E.g. 1.0.0-1-1ubuntuXX
								   rev_num --^^
						 Defaults to: 1
	  -d,--distro [rel]  Specify for which Ubuntu distro the package is
						 designed for (e.g. xenial, bionic, eoan, focal)
	  -k,--key [key]     (optional) GPG key used to sign the package
	  --ppa [name]       (optional) Name of the PPA to upload to
						 Defaults to: ppa:huawei-hiq/ppa
	  --no-publish       Only execute the build; do not publish to a PPA

	Example calls:
	./ubuntu_ppa_upload.bash -u eoan /path/to/src_dir
	./ubuntu_ppa_upload.bash -u xenial --ppa=ppa:huawei-hiq/ppa /path/to/src_dir

As shown above, you can build for various Ubuntu distros simply by calling this script with changing arguments. E.g.

	./ubuntu_ppa_upload.bash -k ABCDEF -u xenial hiq-projectq-0.6.4.post2
	./ubuntu_ppa_upload.bash -k ABCDEF -u bionic hiq-projectq-0.6.4.post2
	./ubuntu_ppa_upload.bash -k ABCDEF -u eoan   hiq-projectq-0.6.4.post2
	./ubuntu_ppa_upload.bash -k ABCDEF -u focal  hiq-projectq-0.6.4.post2

where `ABCDEF` is the GPG key ID of your registered user on Launchpad PPA.

### Manual: build a source package (for e.g. PPA)

#### Building

Go into the root directory of the unpacked package (directory containing the `debian` folder) and give the following command:

	debuild -S -sa

NB: you can add the extra `-uc -us` argument if you do not want to sign the resulting package files.

If you get an error during the build process, please see section [Troubleshooting](#troubleshooting) for some possible solutions.

#### Uploading to a PPA

In order to upload a source package to a PPA on Launchpad, you need to use the following command:

	dput ppa:ppa-name <source.changes>

for example:

	dput ppa:huawei-hiq/ppa hiq-circuit_0.0.2.post4-1ubuntu4~ubuntu20.10_source.changes

NB: you need to sign the package using your registered PGP key in order to upload a package on Launchpad.

### Manual: build a binary package

Go into the root directory of the unpacked package (directory containing the `debian` folder) and give the following command:

	debuild -b -sa

NB: you can add the extra `-uc -us` argument if you do not want to sign the resulting package files.

If you get an error during the build process, please see section [Troubleshooting](#troubleshooting) for some possible solutions.


### Troubleshooting

#### Missing dependencies

If you encounter an error similar to the following one during the build process

	dpkg-checkbuilddeps: error: Unmet build dependencies: python3-matplotlib python3-networkx python3-numpy python3-pybind11 ...

some dependencies required to build the package are not currently found on your system. You need to install the missing dependencies, e.g. using `apt`

	sudo apt install -y python3-matplotlib \
		python3-networkx \
		python3-numpy \
		python3-pybind11 \
		python3-pytest \
		python3-scipy \
		python3-sympy

If some of the packages cannot be found in the official Debian/Ubuntu repositories, you might need to add some PPA to your system repositories. E.g. the Huawei-HiQ PPA

	sudo add-apt-repository ppa:huawei-hiq/ppa
	sudo apt update
