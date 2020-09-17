#! /bin/bash

os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')

YUM=yum

if [ "$os_name" == "centos" ]; then
    if [ $os_ver -eq 7 ]; then
	yum install -y epel-release
	yum install -y centos-release-scl
	yum install -y devtoolset-8
	yum update -y
	echo 'source scl_source enable devtoolset-8' >> ~/.bashrc
	source scl_source enable devtoolset-8
    elif [ $os_ver -eq 8 ]; then
	dnf install -y 'dnf-command(config-manager)'
	dnf config-manager --set-enabled PowerTools
	yum install -y epel-release
	yum update -y
    else
	echo "Unsupported CentOS version: $os_ver"
    fi
    yum install -y yum-utils    
elif [ "$os_name" == "fedora" ]; then
    YUM=dnf
    dnf update -y
    dnf install -y dnf-utils
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi

$YUM install -y rpm-build

cat << EOF > ~/.rpmmacros
%_smp_mflags -j4
%_build_parallel --parallel=4
EOF

