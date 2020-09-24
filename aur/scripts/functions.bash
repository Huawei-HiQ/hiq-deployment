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

# Wrapper function since makepkg cannot be run by root
function makepkg_func()
{
    local var="$@"

    if [ -f /usr/local/bin/makepkg ]; then
	/usr/local/bin/makepkg $var
    else
	sudo -u notroot -- sh -c "makepkg $var"
    fi
}

# ==============================================================================

function in_array()
{
    local needle="$1" arrref="$2[@]" item
    for item in "${!arrref}"; do
        [[ "${item}" == "${needle}" ]] && return 0
    done
    return 1
}

# ------------------------------------------------------------------------------

trim()
{
    local var

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

# ==============================================================================

function get_pkg_fnames()
{
    local pkg_root=$1 pkgs pkgver pkgrel pkgarch

    if ! pushd $pkg_root > /dev/null; then
	exit 1
    fi

    echo "Processing for $pkg_root" 1>&2

    info=$(makepkg_func --printsrcinfo)
    
    pkgs=$(echo "$info" | grep pkgname | cut -d '=' -f2 | trim)
    pkgver=$(echo "$info" | grep pkgver | cut -d '=' -f2 | trim)
    pkgrel=$(echo "$info" | grep pkgrel | cut -d '=' -f2 | trim)
    pkgarch=$(echo "$info" | grep arch | cut -d '=' -f2 | trim)
    
    for pkg in "$pkgs"; do
	fname=${pkg}-${pkgver}-${pkgrel}-${pkgarch}.pkg.tar.zst
	if [ -f $fname ]; then
	    echo $pkg_root/$fname
	elif [ -f $HERE/pkgs/$fname ]; then
	    echo $HERE/pkgs/$fname
	fi
    done

    popd > /dev/null
}

# ==============================================================================

function pkg_builddep()
{
    local pkg_root=$1

    sudo -u notroot -- sh -c "yay -Sy --noconfirm $(pacman --deptest $(source $pkg_root/PKGBUILD && echo ${depends[@]} ${makedepends[@]} ${checkdepends[@]}) | tr '\n' ' ')"
}

# ------------------------------------------------------------------------------

function pkg_build()
{
    local pkg_root=$1

    pushd $pkg_root > /dev/null

    makepkg_func
    
    popd > /dev/null

    pkg_copy $pkg_root

    rm -fv $(get_pkg_fnames $pkg_root)
}

# ------------------------------------------------------------------------------

function pkg_install()
{
    pacman -U --noconfirm "$@"
}

# ------------------------------------------------------------------------------

function pkg_copy()
{
    local pkg_root=$1

    fnames=$(get_pkg_fnames $pkg_root)
    if [ -z "$fnames" ]; then
	echo "Unable to find build packages in $pkg" 1>&2
	exit 1
    fi

    mkdir -p $HERE/pkgs
    for fname in "$fnames"; do
	bname=$(basename $fname)
	if [ ! -f $HERE/pkgs/$bname ]; then
	    cp -v  $fname $HERE/pkgs
	fi
    done
}

# ==============================================================================
