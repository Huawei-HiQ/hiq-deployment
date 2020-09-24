#! /bin/bash
# ==============================================================================
#
# Copyright 2020 <Huawei Technologies Co., Ltd>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ==============================================================================

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

root=$HERE

source $HERE/scripts/functions.bash

os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')

arch_name=$(get_arch_name)
py=3
if [ "$os_name" == "centos" ]; then
    if [ $os_ver -eq 7 ]; then
	py=36
    elif [ $os_ver -eq 8 ]; then
	:
    else
	echo "Unsupported CentOS version: $os_ver"
    fi
elif [ "$os_name" == "fedora" ]; then
    :
elif [ "$os_name" == "opensuse-leap" ]; then
    :
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi

# ==============================================================================

hiq_fermion_deps=(python$py-openfermion)

# ==============================================================================

build_hiq_site_files()
{
    pkg=hiq-site-files
    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	pkg_builddep $root/${pkg}.spec
	pkg_copy_patches $pkg
	pkg_build -ba ${pkg}.spec --without=tests 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    pkg_build -ba $root/${pkg}.spec --without=tests  2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi
	pkg_copy
    fi
}

install_hiq_site_files()
{
    pkg=hiq-site-files
    
    build_hiq_site_files
    rpms=$(get_rpms $pkg)
    pkg_install $rpms
}

# ------------------------------------------------------------------------------

build_hiq_projectq()
{
    install_hiq_site_files

    pkg=hiq-projectq
    deps=(python$py-matplotlib python$py-networkx python$py-numpy
	  python$py-requests python$py-pytest python$py-scipy
	  python$py-sympy python$py-hiq-site-files
	  # Need to manually take care of the dependencies of the dependencies
	  python$py-kiwisolver python$py-decorator pybind11-devel python$py-pybind11
	  python$py-mpmath)

    if [ "$os_name" == "opensuse-leap" ]; then
	deps+=(python$py-Cycler dejavu-fonts texlive-dvipng-bin)
    else
	deps+=(python$py-cycler)
    fi

    args=()
    for pkg_deps in ${deps[@]}; do
	pkg_name=${pkg_deps/python$py-}

	rpms=$(get_rpms $pkg_name)
	if [ -n "$rpms" ]; then
	    for rpm in "$rpms"; do
		args+=($rpm)
	    done
	else
	    args+=($pkg_deps)
	fi
    done
    pkg_install "${args[@]}"

    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	pkg_builddep $root/${pkg}.spec
	if [ $? -ne 0 ]; then
	    exit 1
	fi
	pkg_copy_patches $pkg
	pkg_build -ba ${pkg}.spec 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    pkg_build -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi
	pkg_copy
    fi
}

install_hiq_projectq()
{
    pkg=hiq-projectq
    
    build_hiq_projectq
    rpms=$(get_rpms $pkg)
    pkg_install $rpms
}

# ------------------------------------------------------------------------------

build_hiq_circuit()
{
    install_hiq_site_files
    
    pkg=hiq-circuit

    deps=(mpi4py-common python$py-mpi4py-openmpi python$py-hiq-site-files)

    args=()
    for pkg_deps in ${deps[@]}; do
	pkg_name=${pkg_deps/python$py-}

	rpms=$(get_rpms $pkg_name)
	if [ -n "$rpms" ]; then
	    for rpm in "$rpms"; do
		args+=($rpm)
	    done
	else
	    args+=($pkg_deps)
	fi
    done
    pkg_install "${args[@]}"

    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	pkg_builddep $root/${pkg}.spec
	if [ $? -ne 0 ]; then
	    exit 1
	fi
	pkg_copy_patches $pkg
	pkg_build -ba ${pkg}.spec 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    pkg_build -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi
	pkg_copy
    fi
}

install_hiq_circuit()
{
    pkg=hiq-circuit
    
    install_hiq_projectq
    build_hiq_circuit
    rpms=$(get_rpms $pkg)
    pkg_install $rpms
}

# ------------------------------------------------------------------------------

build_hiq_fermion()
{
    install_hiq_site_files

    src_dir=$(rpmspec --eval '%_sourcedir')
    mkdir -p $src_dir
    cp -v hiq-fermion-0.0.1.tar.gz $src_dir
    pkg=hiq-fermion
    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	pkg_builddep $root/${pkg}.spec
	# Download will always fail on opensuse for now since HiQ-Fermion is
	# not yet on Pypi...
	if [ "$os_name" != "opensuse-leap" ]; then
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi
	pkg_copy_patches $pkg
	pkg_build -ba ${pkg}.spec 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    pkg_build -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi
	pkg_copy
    fi
}

install_hiq_fermion()
{
    install_hiq_projectq
    
    deps=(python$py-h5py python$py-numpy python$py-scipy python$py-pyscf
	  python$py-openfermion python$py-openfermionprojectq)
    
    args=()
    for pkg in ${deps[@]}; do
	pkg_name=${pkg/python$py-}

	rpm_dir=$(rpmspec --eval '%_rpmdir')
		    
	rpms=$(ls $rpm_dir/*/* | grep -i $pkg_name)
	if [ -n "$rpms" ]; then
	    for rpm in "$rpms"; do
		args+=($rpm)
	    done
	else
	    args+=($pkg)
	fi
    done
    pkg_install "${args[@]}"

    build_hiq_fermion
    rpm_dir=$(rpmspec --eval '%_rpmdir')
    rpms=$(ls $rpm_dir/*/* | grep -i hiq-fermion)
    pkg_install $rpms
}

# ==============================================================================

build_hiq_projectq
build_hiq_circuit
build_hiq_fermion

