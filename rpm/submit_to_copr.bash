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

srpms_root=$HERE/srpms

os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')

if [ "$os_name" == "fedora" ]; then
    if ! rpm -q copr-cli > /dev/null; then
	dnf install -y copr-cli
    fi
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi

copr_repo=Huawei-HiQ

if [ ! -f ~/.config/copr ]; then
    echo 'Go to https://copr.fedorainfracloud.org/api/ and then copy-paste the content'
    echo 'here and end your input with Ctrl-D'
    copr_config_data=$(</dev/stdin)
    mkdir -p ~/.config/
    echo "$copr_config_data" > ~/.config/copr
fi

function copr_build()
{
    args=()
    while [ "${1%${1#??}}" == "--" ]; do
	args+=($1)
	shift
    done

    $HERE/scripts/copr_build.bash \
	--os-name=$os_name --os-ver=$os_ver "${args[@]}"\
	"$copr_repo" "${repo_chroot[*]}" "$@"
}

# ==============================================================================

source $HERE/scripts/functions.bash

# ==============================================================================

function get_package_list()
{
    local pkg_list=()

    pkg_list+=("${build_and_install[@]}")
    if [ -z "${build[*]}" ]; then
	for spec in $HERE/deps/*.spec; do
	    bname=$(basename $spec)
	    pkg_name="${bname%.*}"
	    if ! in_array "$pkg_name" pkg_list; then
		pkg_list+=($pkg_name)
	    fi
	done
    else
	pkg_list+=("${build[@]}")
    fi

    pkg_list+=(hiq-projectq hiq-circuit)

    echo "${pkg_list[@]}"
}

function array_intersection()
{
    local array1_ref="$1[@]" array2_ref="$2[@]" array1 array2
    array1=("${!array1_ref}")
    array2=("${!array2_ref}")

    tmp=" ${array2[*]} "
    for item in ${array1[@]}; do
	if [[ $tmp =~ " $item " ]] ; then
	    result+=($item)
	fi
    done
    echo "${result[@]}"
}

# ==============================================================================

declare -A centos fedora opensuse
centos[7]='epel-7-x86_64'
centos[8]='epel-8-x86_64'

fedora[31]='fedora-31-x86_64'
fedora[32]='fedora-32-x86_64'
fedora[33]='fedora-33-x86_64'
fedora[rawhide]='fedora-rawhide-x86_64 '

opensuse[15.1]='opensuse-leap-15.1-x86_64'
opensuse[15.2]='opensuse-leap-15.2-x86_64'


repo_chroot=("${opensuse[@]}")
os_name='opensuse-leap'
os_ver=15.1
copr_build rpm_extra_macros

repo_chroot=("${centos[@]}" "${fedora[31]}" "${opensuse[15.1]}")
os_name='centos'
os_ver=7
copr_build cython

repo_chroot=("${centos[@]}" "${fedora[31]}" "${opensuse[@]}")
os_name='centos'
os_ver=7
copr_build numpy

repo_chroot=("${centos[@]}" "${opensuse[15.1]}")
os_name='centos'
os_ver=7
copr_build --parallel --background networkx mpi4py sympy

repo_chroot=("${centos[7]}" "${opensuse[@]}")
os_name='centos'
os_ver=7
copr_build --parallel --background pybind11

repo_chroot=("${centos[@]}")
os_name='centos'
os_ver=7
copr_build --parallel --background scipy
scipy_build_id=$(copr-cli list-builds $copr_repo | head -n1 | cut -f1)

repo_chroot=("${centos[7]}")
os_name='centos'
os_ver=7
copr_build --parallel --background h5py requests cycler kiwisolver qhull
pandas_build_id=$(copr-cli list-builds $copr_repo | head -n1 | cut -f1)

# Pandas build takes the longest
copr-cli watch-build $pandas_build_id
copr-cli watch-build $scipy_build_id
repo_chroot=("${centos[7]}" "${opensuse[@]}")
copr_build matplotlib

repo_chroot=("${centos[7]}")
copr_build --parallel --background pandas


repo_chroot=("${centos[@]}" "${fedora[@]}" "${opensuse[@]}")
copr_build pubchempy
copr_build --parallel openfermion

repo_chroot=("${centos[@]}" "${opensuse[@]}")
copr_build --parallel pyscf

# ==============================================================================
