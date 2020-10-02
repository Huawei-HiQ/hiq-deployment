# Packaging for Fedora/Centos/RHel

This repository contains the code necessary to build RPM source and binary packages.

## Huawei-HiQ Copr

The Huawei-HiQ Copr repository can be found at the following address: https://copr.fedorainfracloud.org/coprs/huaweihiq/Huawei-HiQ/

It contains all the packages required to run the most recent version of HiQ packages on supported Ubuntu distributions.

### Using the Copr repository

On recent Fedora/CentOS releases, you simply need to issue the following command in a terminal:

	dnf copr enable huaweihiq/Huawei-HiQ
	
On some older distributions, you can try the following:

	yum copr enable huaweihiq/Huawei-HiQ

Alternatively, you can also use one of the `*.repo` files found on the Huawei-HiQ Copr page to add the repository to your current list of repositories.

### Troubleshooting

If for some reason the above command should fail, you might need to install the appropriate plugins for `dnf` or `yum`

	dnf install -y 'dnf-command(copr)'

or in the case of `yum`

	yum install -y yum-plugin-copr

## Environment setup

### DNF systems (Fedora)

Make sure that you have all the basic dependencies installed on your system:

  - rpm-build
  - dnf-plugins-core

You can install them using a command similar to this one

	sudo dnf install -y rpm-build dnf-plugins-core

### YUM systems (old CentOS)

Make sure that you have all the basic dependencies installed on your system:

  - rpm-build
  - yum-utils

You can install them using a command similar to this one

	sudo yum install -y rpm-build yum-utils

### Centos 7

You need to install `epel-release`, `devtoolset-8` and then activate the `devtoolset-8` environment

	sudo yum install -y epel-release centos-release-scl
	sudo yum install -y devtoolset-8
	sudo yum update -y
	source scl_source enable devtoolset-8

### Centos 8

You need to install `epel-release` and enable PowerTools

	sudo dnf install -y 'dnf-command(config-manager)'
	sudo dnf config-manager --set-enabled PowerTools
	sudo dnf install -y epel-release
	sudo dnf update -y

## Build the package

Before building the package, you need to install the required dependencies. You can use the `yum-builddep` command for that

	sudo yum-builddep <file.spec>
	
Note: a similar command exists for `dnf`: `dnf builddep`

If that fails, you might need to manually install some packages using  `yum`; this can be the case if the package you want is not found in any of the official repositories. You might therefore need to install from an RPM file directly before proceeding further.

Once that is done, building the packages is as simply as calling `rpmbuild`

	rpmbuild -ba <file.spec>

NB: if you only want to build a source/binary package you pass the `-bs`/`-bb` option to `rpmbuild` instead of `-ba`.
