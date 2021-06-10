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
os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')

# Requires Bash >= 4
declare -A ubuntu_versions=(["xenial"]="16.04"
			    ["bionic"]="18.04"
			    ["eoan"]="19.10"
			    ["focal"]="20.04"
			    ["groovy"]="20.10"
			    ["hirsute"]="21.04"
			    ["impish"]="21.10")

root=$HERE/deps

output_dir=$root/ppa

pkgs_raw=($(ls -d $root/debian-templates/* | sort))
pkgs=()
for pkg in ${pkgs_raw[@]}; do
    pkgs+=($(basename $pkg | cut -d '-' -f1))
done

BUILD_CMD=$HERE/scripts/build_dep.bash
# BUILD_CMD="$HERE/scripts/build_dep.bash -c --clean-only"
# BUILD_CMD="echo $HERE/scripts/build_dep.bash"

xenial=(chardet idna urllib3 mpmath pybind11 requests sympy)
xenial_bionic=(cython decorator h5py matplotlib mpi4py networkx pandas scipy six)
xenial_bionic_focal=(numpy)
all=(pubchempy openfermion openfermionprojectq pyscf jupyter-react)

if [[ "$os_name" != "ubuntu" ]]; then
    echo 'Need to run under Ubuntu' 1>&2
    exit 1
fi

grp1=()
grp2=()
grp3=()
grp4=()

if [[ "$os_ver" == 16.04 ]]; then
    grp1+=(xenial)
    grp2+=(xenial)
    grp3+=(xenial)
    grp4+=(xenial)
elif [[ "$os_ver" == 18.04 ]]; then
    grp2+=(bionic)
    grp3+=(bionic)
    grp4+=(bionic)
elif [[ "$os_ver" == 20.04 ]]; then
    grp3+=(focal)
    grp4+=(focal)
else
    grp4+=(groovy)
    grp4+=(hirsute)
    grp4+=(impish)
fi

for pkg in "${xenial[@]}"; do
    if [ -z "$(ls -d $root/debian-templates/* | grep $pkg)" ]; then
	echo "Unable to find package: $pkg"
	exit 1
    fi

    for ubuntu in "${grp1[@]}"; do    
	$BUILD_CMD -o $output_dir -d xenial -y $pkg -S -sa -d
    done
done

if [[ "$os_ver" == 16.04 ]]; then
for pkg in "${xenial_bionic[@]}"; do
    if [ -z "$(ls -d $root/debian-templates/* | grep $pkg)" ]; then
	echo "Unable to find package: $pkg"
	exit 1
    fi
    
    for ubuntu in "${grp2[@]}"; do    
	$BUILD_CMD -o $output_dir -d $ubuntu -y $pkg -S -sa -d
    done
done
fi

for pkg in "${xenial_bionic_focal[@]}"; do
    if [ -z "$(ls -d $root/debian-templates/* | grep $pkg)" ]; then
	echo "Unable to find package: $pkg"
	exit 1
    fi
    
    for ubuntu in "${grp3[@]}"; do    
	$BUILD_CMD -o $output_dir -d $ubuntu -y $pkg -S -sa -d
    done
done
for pkg in "${all[@]}"; do
    if [ -z "$(ls -d $root/debian-templates/* | grep $pkg)" ]; then
	echo "Unable to find package: $pkg"
	exit 1
    fi
    
    for ubuntu in "${grp4[@]}"; do    
	$BUILD_CMD -o $output_dir -d $ubuntu -y $pkg -S -sa -d
    done
done
