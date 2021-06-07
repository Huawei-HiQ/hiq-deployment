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

function trim()
{
    if [ $# -eq 1 ]; then
	var=$1
    else
	read var
    fi

    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo $var
}

function get_version()
{
    local pkg_dir=$1
    dpkg-parsechangelog -c 1 -l $pkg_dir/debian/changelog -S Version \
	   | sed 's/^[0-9]\+://'
}

function gen_version()
{
    local pkg_dir=$1 ubuntu_num=$2
    version=$(get_version $pkg_dir)
    # version=$(echo $version | sed -e 's/ppa[0-9]\+~ubuntu[0-9][0-9].[0-9][0-9]//')
    # version=$(echo $version | sed -e 's/-[0-9]\+ubuntu[0-9]\+~ubuntu[0-9][0-9].[0-9][0-9]//')
    if [ $# -gt 1 ]; then
	if [ -n "$ppa_rev" ]; then
	    echo "${version}ppa${ppa_rev}~ubuntu$ubuntu_num"
	else
	    echo "${version}~ubuntu$ubuntu_num"
	fi
    else
	if [ -n "$ppa_rev" ]; then
	    echo "${version}ppa${ppa_rev}"
	else
	    echo "${version}"
	fi
    fi
}

function backup_files()
{
    pkg_dir=$1
    shift

    backup_dir=$backup_dir/$(basename $pkg_dir)
    mkdir -p $backup_dir
    
    for f in "$@"; do
	if [ -f $backup_dir/${f}.bak ]; then
	    mv -v $backup_dir/${f}.bak $pkg_dir/debian/${f}
	fi
	if dirname ${f}; then
	    mkdir -p $backup_dir/$(dirname ${f})
	fi
	cp -v $pkg_dir/debian/${f} $backup_dir/${f}.bak
    done
    chown -R --reference=$pkg_dir/debian/ $backup_dir
}

# ==============================================================================

# save_function foo old_foo
save_function() {
    local ORIG_FUNC=$(declare -f $1)
    local NEWNAME_FUNC="$2${ORIG_FUNC#$1}"
    eval "$NEWNAME_FUNC"
}

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1 pkg_archive_name
    if [ $# -gt 1 ]; then
	pkg_archive_name=$2
    else
	pkg_archive_name=$pkg_name
    fi

    orig_tar_gz=$root/${pkg_name}_$pkg_ver.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	python3 -m pip download --no-binary ":all:" "$pkg_name==$pkg_ver" --no-deps 1>&2
	mv -v ${pkg_archive_name}-$pkg_ver.tar.gz $orig_tar_gz 1>&2
    fi
    echo $orig_tar_gz
}

# ------------------------------------------------------------------------------

function pkg_update_changelog()
{
    local pkg_dir=$1 ubuntu=$2 ubuntu_num=$3
    pkg_name=$(dpkg-parsechangelog -c 1 -l $pkg_dir/debian/changelog -S Source)
    version=$(gen_version $pkg_dir $ubuntu_num)
    
    dch -p \
	-c $pkg_dir/debian/changelog \
	-D $ubuntu --force-distribution \
	-v "$version" \
	Ubuntu $ubuntu build
}

# ------------------------------------------------------------------------------

function pkg_apply_patches()
{
    local pkg_dir=$1

    pushd $pkg_dir
    if [ -d debian/patches ]; then
	if type dquilt 2> /dev/null > /dev/null; then
	    dquilt push -a
	else
	    QUILT_PATCHES=debian/patches quilt push -a
	fi
    fi
    popd
}

# ------------------------------------------------------------------------------

function pkg_build()
{
    pushd $1
    shift
    debuild "$@"
    ret=$?
    popd
    return $ret
}

# ------------------------------------------------------------------------------

function pkg_sign()
{
    local pkg_dir=$1
    shift
    version=$(get_version $pkg_dir)

    fargs=($root/${pkg_name}_${version}_source.dsc
	   $root/python-${pkg_name}_${version}_source.dsc
	   $root/${pkg_name}_${version}_source.changes
	   $root/python-${pkg_name}_${version}_source.changes
	   $root/${pkg_name}_${version}_amd64.changes
	   $root/python-${pkg_name}_${version}_amd64.changes)
    for file in "${fargs[@]}"; do
	if [ -f $file ]; then
	    debsign "$@" $file
	fi
    done
}

function pkg_move_results()
{
    local pkg=$1 output_dir=$2
    pkg_dir=$(basename $(ls -d $templates_dir/* | grep $pkg | sort | tr ' ' '\n' | tail -n1))
    if [ -z "$pkg_dir" ]; then
	die "Missing folder in $templates_dir!"
    fi
    pkg_name=$pkg
    pkg_ver=${pkg_dir##$pkg-}
    pkg_dir=$root/$pkg_dir

    version=$(get_version $pkg_dir)

    mkdir -p $output_dir

    fargs=($root/${pkg_name}_${version}.debian.tar.xz
	   $root/python-${pkg_name}_${version}.debian.tar.xz
	   $root/${pkg_name}_${version}.dsc
	   $root/python-${pkg_name}_${version}.dsc
	   $root/${pkg_name}_${version}_source.changes
	   $root/python-${pkg_name}_${version}_source.changes
	   $root/${pkg_name}_${version}_source.build
	   $root/python-${pkg_name}_${version}_source.build
	   $root/${pkg_name}_${version}_source.buildinfo
	   $root/python-${pkg_name}_${version}_source.buildinfo)
    for file in "${fargs[@]}"; do
	if [ -f $file ]; then
	    mv -v $file $output_dir
	fi
    done

    fargs=($root/${pkg_name}_${pkg_ver}.orig.tar.gz
	   $root/python-${pkg_name}_${pkg_ver}.orig.tar.gz
	   $root/${pkg_name}_${pkg_ver}.orig.tar.xz
	   $root/python-${pkg_name}_${pkg_ver}.orig.tar.xz)
    for file in "${fargs[@]}"; do
	if [ -f $file ]; then
	    cp -v $file $output_dir
	fi
    done
}

# ==============================================================================
