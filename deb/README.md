# Packaging for Debian/Ubuntu

This repository contains the code necessary to build DEB source and binary packages.

## Huawei-HiQ PPA

The Huawei-HiQ PPA can be found at the following address: https://launchpad.net/~huawei-hiq/+archive/ubuntu/ppa.

It contains all the packages required to run the most recent version of HiQ packages on supported Ubuntu distributions.

### Using the PPA

The simplest way of using this PPA is by using the `add-apt-repository` command:

	sudo add-apt-repository ppa:huawei-hiq/ppa
	sudo apt-get update

### Troubleshooting

If that command is not found on your system, you may install it using:

	apt install -y software-properties-common
	
In some cases, errors mentioning a GPG public key may happen. In that case, please manually add the GPG key from Huawei-HiQ:

	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9071AE544115FB0C

## Building a DEB package

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

### Automated setup and build

The easiest way to setup your environment to build one of the DEB packages is to use either `build_dep.bash` or `build_hiq.bash` from the `script` directory. You will find below the help message for the former for convenience:

	Usage:
	   build_dep.bash [options] pkg_name [debuild options]

	Options:
	  -h,--help          Show this help message and exit
	  -c,--clean         (optional) start from clean folder
	  --clean-only       (optional) only perform clean step
	  -d,--distro [rel]  Specify for which Ubuntu distro the package is
						 designed for (e.g. xenial, bionic, eoan, focal)
	  -o,--output [dir]  (optional) Specify output directory for generated
						 files
						 Defaults to: /pkg/deb/scripts/../deps/
	  -y,--yes           Assume yes to all prompts

	Any options passede *after* the package name will be forwarded to
	`debuild`

	Example calls:
	./scripts/build_dep.bash -d eoan -y urllib3
	./scripts/build_dep.bash -d xenial -o /tmp/data cython -S -sd

Note that you will need to have `pip` installed on your system for this script to work. You can install it using a command similar to

	sudo apt install -y python3-pip

#### Script functionality

Here is a short rundown on how the automated scripts works. For this example, we will assume the following invocation:

	./scripts/build_hiq.bash -d xenial hiq-projectq -S -sd

Both `build_hiq.bash` and `build_dep.bash` scripts work in similar fashion. Both of these look into the `debian-templates` directory (`deps/debian-templates` in the case of `build_dep.bash`) for a folder with a name matching the one your are currently trying to build. In our example, this will be:

	hiq-projectq-0.6.4.post2

From the directory name, we extract the package name (`hiq-projectq`) and its version (`0.6.4.post2`). The script will then source the `_${pkg_name}_config.bash` file which may contain function overload (in case you to override some basic functionality). This file should in any case contain a definition of the `pkg_prepare` function, which role is to do any changes to the source directory _after_ the package archive is unpacked, but _before_ the build process starts.

The script then calls the `pkg_download` BASH function to download the package archive and unpacks the sources. If the `debian/` directory does not exist in the unpacked source, the script will then copy the content of `debian-templates/pkg_name-pkg_version` into the source folder.

After that, the script will call the following functions in order:

1. `pkg_prepare`
2. `pkg_apply_patches`
3. `backup_files` in order to create a backup of the changelog file)
4. `pkg_update_changelog`

If the user approves of the changes that have (possibly) been made, the script will then download all unmet dependencies and start building the package using the `debuild` command. Any argument passed to the build scripts that appear _after_ the package name on the command line (`-S -sd` in our example) will be passed onto `debuild`.

After the build is finished, the script will call the `pkg_sign` to sign all the relevant files with GPG.

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

#### GPG Key

In order to submit your package to a repository, you might need to sign it using a GPG key. In order to facilitate the building process, you can add this line to the `~/.devscripts` file (create it if it does not already exist)

	DEBSIGN_KEYID="key-id"

where you would replace `key-id` with your own GPG key identifier.

### Manual: build a source package (for e.g. PPA)

#### Building

Go into the root directory of the unpacked package (directory containing the `debian` folder) and give the following command:

	debuild -S -sa

NB: you can add the extra `-uc -us` argument if you do not want to sign the resulting package files. You can also us `-sd` if you do not want to include the original source code archive in the submission.

If you get an error during the build process, please see section [Troubleshooting](#troubleshooting) for some possible solutions.

#### Uploading to a PPA

In order to upload a source package to a PPA on Launchpad, you need to use the following command:

	dput ppa:ppa-name <source.changes>

for example:

	dput ppa:huawei-hiq/ppa hiq-circuit_0.0.2.post4-1ubuntu1ppa1~ubuntu20.10_source.changes

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
	# This next line might not be needed on Ubuntu > 16.04
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9071AE544115FB0C
	sudo apt update
