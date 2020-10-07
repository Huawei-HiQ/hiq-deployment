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
root=$HERE/../deps

config_dir=$root
templates_dir=$root/debian-templates

# ==============================================================================
# Process arguments

source $HERE/_build_args.bash
backup_dir=$root/backup

# ==============================================================================
# Setup directory

source $HERE/_build_setup.bash

# ------------------------------------------------------------------------------
# Setup debian sub-directory

if [ ! -d $pkg_dir/debian ]; then
    cp -rv $templates_dir/$(basename $pkg_dir) $pkg_dir/debian
    chown -R --reference=$templates_dir $pkg_dir/debian
fi

pkg_prepare $pkg_dir
pkg_apply_patches $pkg_dir
backup_files $pkg_dir changelog
pkg_update_changelog $pkg_dir $ubuntu_distro $ubuntu_distro_num

echo '========================================'
echo 'Content of debian/changelog'
echo ''
dpkg-parsechangelog -l $pkg_dir/debian/changelog
echo '========================================'

response=${response,,}    # tolower
if [ $assume_yes -eq 1 ]; then
    echo "Is this ok? [Y/n] Y"
else
    read -r -p "Is this ok? [Y/n] " response
    if [[ ! "$response" =~ ^(yes|y|)$ ]]; then
	exit 1
    fi
fi

# ------------------------------------------------------------------------------
# Install depdendencies

pushd $pkg_dir > /dev/null
for i in {1..4}; do
    unmet_deps=$(dpkg-checkbuilddeps 2>&1 \
		     | sed -e 's/dpkg-checkbuilddeps: error: Unmet build dependencies://' \
			   -e 's/(.*)//g')

    if [ -z "$unmet_deps" ]; then
	break
    fi

    simple_unmet_deps=$(echo $unmet_deps | sed 's/\([^ ]\+ | [^ ]\+\)//g' \
			    | sed 's/[ ]\+/ /' | awk '{ print length, $0 }' \
			    | sort -nr | cut -d' ' -f2- | tr '\n' ' ')

    complex_unmet_deps=$unmet_deps
    for dep in $simple_unmet_deps; do
	complex_unmet_deps=$(echo $complex_unmet_deps | sed "s/$dep//g")
    done
    complex_unmet_deps=$(echo $complex_unmet_deps | tr -d '|' \
			     | sed 's/[ ]\+/ /')

    deps=()
    for dep in $complex_unmet_deps; do
	if [ -z "$(apt-cache showsrc $dep 2>&1 > /dev/null)" ]; then
	   deps+=($dep)
	fi
    done

    if [ -n "$simple_unmet_deps${deps[*]}" ]; then
	if ! apt install -y $simple_unmet_deps "${deps[@]}"; then
	    exit 1
	fi
    fi
done
popd > /dev/null

# ------------------------------------------------------------------------------
# Build!

pkg_build $pkg_dir "${args[@]}"
if [ $? -ne 0 ]; then
   exit 1
fi
pkg_sign $pkg_dir --no-re-sign

if [ -n "$output_dir" ]; then
    pkg_move_results $pkg $output_dir
fi

# ==============================================================================
