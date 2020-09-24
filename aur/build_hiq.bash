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

# ==============================================================================

source $HERE/scripts/functions.bash

# ==============================================================================

build_hiq_projectq()
{
    pkg=hiq-projectq
    
    rpms=$(get_pkg_fnames $pkg)
    if [ -z "$rpms" ]; then
	pkg_builddep $pkg
	if [ $? -ne 0 ]; then
	    exit 1
	fi

	pkg_build $pkg
	pkg_copy $pkg
    fi
}

install_hiq_projectq()
{
    pkg=hiq-projectq
    
    build_hiq_projectq
    pkgs=$(get_pkg_fnames $pkg)
    if [ -z "$pkgs" ]; then
	echo "Unable to find build packages in $pkg" 1>&2
	exit 1
    else
	if [ -n "$(echo $pkgs | grep python3)" ]; then
	    pkgs=$(get_pkg_fnames $pkg | grep python3)
	fi
    fi
    pkg_install $pkgs
}

# ------------------------------------------------------------------------------

build_hiq_circuit()
{
    pkg=hiq-circuit

    rpms=$(get_pkg_fnames $pkg)
    if [ -z "$rpms" ]; then
	pkg_builddep $pkg
	if [ $? -ne 0 ]; then
	    exit 1
	fi

	pkg_build $pkg
	pkg_copy $pkg
    fi
}

install_hiq_circuit()
{
    pkg=hiq-circuit
    
    install_hiq_projectq
    
    build_hiq_circuit
    pkgs=$(get_pkg_fnames $pkg)
    if [ -z "$pkgs" ]; then
	echo "Unable to find build packages in $pkg" 1>&2
	exit 1
    else
	if [ -n "$(echo $pkgs | grep python3)" ]; then
	    pkgs=$(get_pkg_fnames $pkg | grep python3)
	fi
    fi
    pkg_install $pkgs
}

# ------------------------------------------------------------------------------

build_hiq_fermion()
{
    pkg=hiq-fermion

    rpms=$(get_pkg_fnames $pkg)
    if [ -z "$rpms" ]; then
	pkg_builddep $pkg
	if [ $? -ne 0 ]; then
	    exit 1
	fi

	pkg_build $pkg
	pkg_copy $pkg
    fi
}

install_hiq_fermion()
{
    pkg=hiq-fermion
    install_hiq_projectq

    # NB: '-' at the end used for filtering
    deps=(python-openfermion- python-openfermionprojectq-)
    
    args=()
    for pkg in ${deps[@]}; do
	pkg_name=${pkg#python-}

	pkgs=$(ls $root/pkgs/* | grep -i $pkg_name)
	if [ -n "$pkgs" ]; then
	    for pkg in "$pkgs"; do
		args+=($pkg)
	    done
	else
	    args+=($pkgs)
	fi
    done
    pkg_install "${args[@]}"

    build_hiq_fermion
    pkgs=$(get_pkg_fnames $pkg)
    if [ -z "$pkgs" ]; then
	echo "Unable to find build packages in $pkg" 1>&2
	exit 1
    else
	if [ -n "$(echo $pkgs | grep python3)" ]; then
	    pkgs=$(get_pkg_fnames $pkg | grep python3)
	fi
    fi
    pkg_install $pkgs
}

# ==============================================================================

build_hiq_projectq
build_hiq_circuit
# build_hiq_fermion

