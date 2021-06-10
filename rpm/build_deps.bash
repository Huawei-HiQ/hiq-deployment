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

root=$HERE/deps

source $HERE/scripts/functions.bash

os_name=$(cat /etc/os-release | grep ^ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')
arch_name=$(get_arch_name)

if [ -z "$(rpm --eval '%{?dist:%dist}')" ]; then
    alias pkg_build="pkg_build -D 'dist $arch_name'"
fi

if [ "$os_name" == "centos" ]; then
    if [ -n "$(cat /etc/os-release | grep ^NAME= | sort | head -n1 | cut -d '=' -f2 | tr -d '"' | grep -i stream)" ]; then
        os_ver=stream
    fi
fi

# ==============================================================================

source $HERE/scripts/packages.bash

# ==============================================================================

rpms=$(ls $HERE/rpms/ | egrep "rpm$" | grep -- $arch_name)
for rpm in $rpms; do
    rpm_dir=$(rpmspec --eval '%_rpmdir')
    mkdir -p $rpm_dir/x86_64/
    mkdir -p $rpm_dir/noarch/

    if [[ -n "$(echo $rpm | grep x86_64)" && ! -f $rpm_dir/x86_64/$rpm ]]; then
	/bin/cp -v $HERE/rpms/$rpm $rpm_dir/x86_64/
    fi
    if [[ -n "$(echo $rpm | grep noarch)" && ! -f $rpm_dir/noarch/$rpm ]]; then
	/bin/cp -v $HERE/rpms/$rpm $rpm_dir/noarch/
    fi
done

srpms=$(ls $HERE/srpms/ | egrep "rpm$" | grep -- $arch_name)
if [ -n "$srpms" ]; then
    srpm_dir=$(rpmspec --eval '%_srcrpmdir')
    mkdir -p $srpm_dir
    for rpm in $srpms; do
	if [ ! -f $srpm_dir/$rpm ]; then
	    /bin/cp -v $HERE/srpms/$rpm $srpm_dir
	fi
    done
fi

for pkg in ${build_and_install[@]}; do
    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	pkg_builddep $root/${pkg}.spec
	pkg_copy_patches $pkg
	pkg_build -ba $root/${pkg}.spec 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    pkg_build -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi

	pkg_copy
	rpms=$(cat /tmp/rpms.txt | egrep -v 'src.rpm$')
    fi
    pkg_install $rpms
done

tmp="${build[@]}"
if [[ -n "$tmp" ]]; then
    specs=""
    for pkg in ${build[@]}; do
	specs="$specs $root/${pkg}.spec"
    done
else
    specs=$(ls $root/*.spec)
fi

for spec in $specs; do
    bname=$(basename $spec)
    pkg=${bname/.spec}

    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	if ! in_array $pkg build_and_install; then
	    pkg_builddep $root/${pkg}.spec
	    pkg_copy_patches $pkg
	    pkg_build -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		pkg_build -ba $root/${pkg}.spec 2>&1 | capture_rpms
		if [ $? -ne 0 ]; then
		    exit 1
		fi
	    fi

	    pkg_copy
	fi
    fi
done

# ==============================================================================
