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
source $HERE/scripts/packages.bash

# ==============================================================================

for pkg in ${build_and_install[@]}; do
    pkgs=$(get_pkg_fnames $pkg)
    if [ -z "$pkgs" ]; then
	pkb_builddep $pkg
	pkg_build $pkg
	pkg_copy $pkg

	pkgs=$(get_pkg_fnames $pkg)
	if [ -z "$pkgs" ]; then
	    echo "Unable to find build packages in $pkg" 1>&2
	    exit 1
	else
	    if [ -n "$(echo $pkgs | grep python3)" ]; then
		pkgs=$(get_pkg_fnames $pkg | grep python3)
	    fi
	fi
    fi

    pkg_install $pkgs -dd
done

tmp="${build[@]}"
if [[ -n "$tmp" ]]; then
    pkgbuilds=""
    for pkg in ${build[@]}; do
	pkgbuilds="$pkgbuilds $root/$pkg/PKGBUILD"
    done
else
    pkgbuilds=$(ls $root/*/PKGBUILD)
fi

for pkgbuild in $pkgbuilds; do
    dirname=$(dirname $pkgbuild)
    pkg=$(basename $dirname)

    pkgs=$(get_pkg_fnames $pkg)
    if [ $? -ne 0 ]; then
	exit 1
    fi
    if [ -z "$pkgs" ]; then
	if ! in_array $pkg build_and_install; then
	    pkg_builddep $pkg
	    pkg_build $pkg
	    pkg_copy $pkg
	fi
    fi
done
