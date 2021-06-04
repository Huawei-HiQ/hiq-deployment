#! /bin/bash

os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')

YUM=yum

if [ "$os_name" == "centos" ]; then
    if [ -n "$(cat /etc/os-release | grep ^NAME= | sort | head -n1 | cut -d '=' -f2 | tr -d '"' | grep -i stream)" ]; then
        os_ver=stream
    fi

    if [[ "$os_ver" == "stream" || $os_ver -eq 8 ]]; then
        YUM=dnf
	dnf install -y 'dnf-command(config-manager)'
	dnf config-manager --set-enabled powertools
	dnf install -y epel-release
	dnf update -y
        dnf install -y dnf-utils
        dnf copr enable -y huaweihiq/Huawei-HiQ
    elif [ $os_ver -eq 7 ]; then
        YUM=yum
	yum install -y epel-release
	yum install -y centos-release-scl
	yum install -y devtoolset-8
	yum update -y
	echo 'source scl_source enable devtoolset-8' >> ~/.bashrc
	source scl_source enable devtoolset-8
        yum install -y yum-utils yum-plugin-copr
        yum copr enable -y huaweihiq/Huawei-HiQ
    else
	echo "Unsupported CentOS version: $os_ver"
    fi
elif [ "$os_name" == "fedora" ]; then
    YUM=dnf
    dnf update -y
    dnf install -y dnf-utils
    dnf copr enable -y huaweihiq/Huawei-HiQ
elif [ "$os_name" == "opensuse-leap" ]; then
    YUM=zypper
    if [[ "$os_ver" == "15.1" || "$os_ver" == "15.2" || "$os_ver" == "15.3" ]]; then
	zypper update -y
	zypper install -y python3-pip wget
	python3 -m pip install python-rpm-spec

	cat << EOF > /usr/local/bin/get_sources
#! /usr/bin/python3

import subprocess
import sys
from pyrpm.spec import Spec, replace_macros

spec = Spec.from_file(sys.argv[1])

for idx, source in enumerate(spec.sources):
    if 'pypi_source' in source:
        data = subprocess.check_output(
            ('rpmspec', '--parse', sys.argv[1])).decode()
        sources = [line for line in data.split('\n') if 'Source' in line]
        for source in sources:
            print(source.split()[-1])
    else:
        print(replace_macros(source, spec))

for patch in spec.patches:
    print(replace_macros(patch, spec))
EOF
	cat << \EOF > /usr/local/bin/download_sources
#! /bin/bash

src_dir=$(rpmspec --eval '%_sourcedir')
sources=$(get_sources "$@")
mkdir -p $src_dir
if [ -n "$sources" ]; then
    for file in "$sources"; do
    	wget -NP "$src_dir" $file
    done
fi
EOF

	cat << \EOF > /usr/local/bin/zypper-builddep
#! /bin/bash
deps=$(rpmspec -q "$@" --buildrequires)
if [ -n "$deps" ]; then
    zypper install -y $deps
fi
src_dir=$(rpmspec --eval '%_sourcedir')
sources=$(get_sources "$@")
mkdir -p $src_dir
if [ -n "$sources" ]; then
    for file in "$sources"; do
    	wget -NP "$src_dir" $file
    done
fi
EOF
	chmod 755 /usr/local/bin/get_sources
	chmod 755 /usr/local/bin/download_sources
	chmod 755 /usr/local/bin/zypper-builddep
    else
	echo "Unsupported OpenSUSE version: $os_ver"
    fi
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi

$YUM install -y rpm-build

if [ "$os_name" == "opensuse-leap" ]; then
cat << EOF > ~/.rpmmacros
%_smp_mflags -j4
EOF
else
cat << EOF > ~/.rpmmacros
%_smp_mflags -j4
%_build_parallel --parallel=4
EOF
fi
