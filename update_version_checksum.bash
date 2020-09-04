#! /bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DIFF_CMD=diff
if command -v colordiff &> /dev/null; then
    DIFF_CMD=colordiff
fi

# ==============================================================================

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error

trim()
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

# ==============================================================================

pkg_name=$1
pkg_ver=$(python3 -m pip show $pkg_name | grep Version | cut -d ':' -f2 | trim)

if python3 -m pip download --no-binary ":all:" $pkg_name --no-deps; then
    pkg_targz=${pkg_name}-${pkg_ver}.tar.gz

    if [ ! -f "$pkg_targz" ]; then
    	die "Unable to find downloaded archive: $pkg_targz"
    fi
else
    die "Failed to download the source archive for $pkg_name!"
fi

pkg_sha256=$(sha256sum $pkg_targz | cut -d ' ' -f1)

# ==============================================================================
# AUR package

fname_aur=$HERE/aur/${pkg_name}/PKGBUILD
if [ -f $fname_aur ]; then
    sed_args_aur=(-e "/pkgver=/c pkgver=$pkg_ver"
		  -e "/sha256sums=/c sha256sums=('$pkg_sha256')")

    echo '========== AUR =========='
    sed "${sed_args_aur[@]}" $fname_aur | $DIFF_CMD -U1 $fname_aur -
    echo '---------- AUR ----------'
fi

# ------------------------------------------------------------------------------
# Mac OS Homebrew

fname_brew=$HERE/Formula/${pkg_name}.rb
if [ -f $fname_brew ]; then
    # Requires Bash >= 4.2
    url=$(cat $fname_brew | grep url | trim | cut -d ' ' -f2)
    url="${url:1:-1}"
    url_main=$(echo "$url" | rev | cut -d '/' -f2- | rev)
    url_new="$url_main/$pkg_targz"

    sed_args_brew=(-e "/url \"https:\/\/pypi.io\/packages\/source/c\  url \"$url_new\""
		   -e "/sha256 \"/c\  sha256 \"$pkg_sha256\"")

    has_version=$(cat $fname_brew | grep version)
    if [ -n "$has_version" ]; then
	normalized=$(echo $pkg_ver | cut -d '.' -f-3)
	sed_args_brew+=(-e "/version \"/c\  version \"$normalized\"")
    fi

    echo '========== BREW =========='
    sed "${sed_args_brew[@]}" $fname_brew | $DIFF_CMD -U1 $fname_brew -
    echo '---------- BREW ----------'
fi

# ------------------------------------------------------------------------------
# DEB package

dname_deb=$HERE/deb/${pkg_name}
if [ ! -d $dname_deb ]; then
    dname_deb=$HERE/deb/${pkg_name}-*
fi

# ------------------------------------------------------------------------------
# RPM package

fname_rpm=$HERE/rpm/${pkg_name}.spec
if [ -f $fname_rpm ]; then
    pkg_name_norm=${pkg_name//-/_}
    pkg_rel=$(echo $pkg_ver | cut -d '.' -f2)

    sed_args_rpm=(-e "/%global ${pkg_name_norm}_version/c %global ${pkg_name_norm}_version $pkg_ver"
		  -e "/%global ${pkg_name_norm}_release/c %global ${pkg_name_norm}_release $pkg_rel"
		  -e "/%global sha256/c %global sha256 $pkg_sha256")

    echo '========== RPM =========='
    sed "${sed_args_rpm[@]}" $fname_rpm | $DIFF_CMD -U1 $fname_rpm -
    echo 'Make sure that 3 %global have been modified!'
    echo '---------- RPM ----------'
fi

# ==============================================================================

read -r -p "Is this ok? [Y/n] " response
echo -e "'$response'"
response=${response,,}    # tolower
if [[ ! "$response" =~ ^(yes|y|)$ ]]; then
    exit 1
fi

if [ -n "${sed_args_aur[@]}" ]; then
    sed -i "${sed_args_aur[@]}" $fname_aur
fi
if [ -n "${sed_args_brew[@]}" ]; then
    sed -i "${sed_args_brew[@]}" $fname_brew
fi
if [ -n "${sed_args_rpm[@]}" ]; then
    sed -i "${sed_args_rpm[@]}" $fname_rpm
fi

if [ -d $dname_deb ]; then
    bash $HERE/deb/setup.bash --${pkg_name/hiq-} $HERE/deb
fi

# ==============================================================================
