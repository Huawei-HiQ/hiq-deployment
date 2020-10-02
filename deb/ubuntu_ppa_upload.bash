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

UBUNTU_PPA=ppa:huawei-hiq/ppa
debuild_args=()
gpg_key=$GPG_KEY
ubtu_ver_rev=1
do_dput=1

# Requires Bash >= 4
declare -A ubuntu_versions=(["xenial"]="16.04"
			    ["bionic"]="18.04"
			    ["eoan"]="19.10"
			    ["focal"]="20.04"
			    ["groovy"]="20.10")

global_dependencies=('${shlibs:Depends}' '${misc:Depends}' '${python3:Depends}')

# ==============================================================================

source $HERE/scripts/functions.bash

modify_change_log()
{
    ubuntu=$1
    ubuntu_num=$2
    ubtu_ver_rev=$3
    pkg_name=$(dpkg-parsechangelog -c 1 | grep Source | cut -d ':' -f2 | trim)
    version=$(gen_version $ubuntu_num)
    
    dch -p \
	-D $ubuntu --force-distribution \
	-v "$version" \
	Ubuntu $ubuntu build
}

do_backup()
{
    cp -v debian/changelog ../changelog.bak
    cp -v debian/control ../control.bak
}

undo_backup()
{
    mv -v ../changelog.bak debian/changelog
    mv -v ../control.bak debian/control    
}

# ==============================================================================

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
no_arg() {
    if [ -n "$OPTARG" ]; then die "No arg allowed for --$OPT option"; fi; }
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

python_setup() { python3 setup.py $1 2> /dev/null; }

help_message() {
    echo -e '\nUsage:'
    echo "  " `basename $0` "[options] src_dir"
    echo -e '\nOptions:'
    echo '  -h,--help          Show this help message and exit'
    echo '  -n [rev_num]       (optional) Revision number for ubuntu version number'
    echo '                     E.g. 1.0.0-1-1ubuntuXX'
    echo '                                     n --^^'
    echo "                     Defaults to: $ubtu_ver_rev"
    echo '  -d,--distro [rel]  Specify for which Ubuntu distro the package is'
    echo '                     designed for (e.g. xenial, bionic, eoan, focal)'
    echo '  -k,--key [key]     (optional) GPG key used to sign the package'
    if [ -n "$GPG_KEY" ]; then
	echo "                     Defaults to: $GPG_KEY"
    fi
    echo '  --ppa [name]       (optional) Name of the PPA to upload to'
    echo "                     Defaults to: $UBUNTU_PPA"
    echo '  --no-publish       Only execute the build; do not publish to a PPA'
    echo -e '\nExample calls:'
    echo "$0 -u eoan /path/to/src_dir"
    echo "$0 -u xenial --ppa=$UBUNTU_PPA /path/to/src_dir"
}

# ------------------------------------------------------------------------------

while getopts hk:d:n:-: OPT; do
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi

  case "$OPT" in
      h | help )    no_arg;
		    help_message >&2
		    exit 1 ;;
      n )           needs_arg;
		    ubtu_ver_rev=$OPTARG
		    ;;
      d | distro )  needs_arg;
		    ubuntu_distro=$OPTARG
		    ;;
      k | key )     needs_arg;
		    gpg_key=$OPTARG
		    ;;
      ppa )         needs_arg;
		    UBUNTU_PPA=$OPTARG
		    ;;
      no-publish )  no_arg;
		    do_dput=0
		    ;;
    ??* )           die "Illegal option --OPT: $OPT" ;;
    \? )            exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

# ==============================================================================

if [ $# -lt 1 ]; then
    die "Usage: $(basename $0) source_directory"
    exit 1
fi

src_dir=$1
shift

if [ ! -d $src_dir ]; then
    die "$src_dir is not a valid directory"
fi

# Get Ubuntu distro name and version number
if [ -z "$ubuntu_distro" ]; then
    die "Missing -u,--ubuntu!"
fi
ubuntu_distro_num=${ubuntu_versions[$ubuntu_distro]}
if [ -z "$ubuntu_distro_num" ]; then
    die "Invalid distro name: $ubuntu_distro (allowed values: ${!ubuntu_versions[@]})"
fi

# Handle GPG key if present
if [ -n "$gpg_key" ]; then
    # Test that GPG key exists
    if ! gpg -k $GPG_KEY > /dev/null 2> /dev/null ; then
	die "Unable to find GPG key $GPG_KEY"
    fi
    
    debuild_args=(-k$gpg_key)
else
    debuild_args=(-uc -us)
fi

# ==============================================================================

cd $src_dir

echo 'Will be building the following DEB package:'
echo "  - package location: $src_dir"
echo "  - package version:  $(gen_version $ubuntu_distro_num)"
echo "  - Ubuntu version:   $ubuntu_distro ($ubuntu_distro_num)"
if [ $do_dput -eq 1 ]; then
    echo "  - PPA destination:  $UBUNTU_PPA"
fi
if [ -n "$gpg_key" ]; then
    echo "  - GPG key:          $gpg_key"
fi
read -r -p "Is this ok? [Y/n] " response
response=${response,,}    # tolower
if [[ ! "$response" =~ ^(yes|y|)$ ]]; then
    exit 1
fi

# ------------------------------------------------------------------------------

unmet_dependencies=$(dpkg-checkbuilddeps 2>&1 | cut -d ':' -f 4)

if [ -n "$unmet_dependencies" ]; then
    echo "Found some unmet dependencies: $unmet_dependencies"
    echo "  -> will try to install them now"
    set -x
    if [ "$(id -u)" == "0" ]; then
	apt install -y $unmet_dependencies
    else
	sudo apt install -y $unmet_dependencies
    fi
    set +x
fi

# ------------------------------------------------------------------------------

pkg_name=$(dpkg-parsechangelog -c 1 | grep Source | cut -d ':' -f2 | trim)
pkg_ver=$(gen_version $ubuntu_distro_num)
changes_file=${pkg_name}_${pkg_ver}_source.changes

# --------------------------------------

if [[ $pkg_name == "hiq-projectq"  ]]; then
    source $HERE/scripts/_ubuntu_ppa_upload_hiq_projectq.bash
elif [[ $pkg_name == "hiq-circuit"  ]]; then
    source $HERE/scripts/_ubuntu_ppa_upload_hiq_circuit.bash
else
    die "Unknown package: $pkg_name"
fi

do_backup

modify_change_log $ubuntu_distro $ubuntu_distro_num $ubtu_ver_rev
change_control_dependencies $ubuntu_distro debian/control

echo '========================================'
echo 'Content of debian/changelog'
echo ''
dpkg-parsechangelog
echo '----------------------------------------'
echo 'Content of debian/control'
echo ''
cat debian/control
echo '========================================'

read -r -p "Is this ok? [Y/n] " response
response=${response,,}    # tolower
if [[ ! "$response" =~ ^(yes|y|)$ ]]; then
    undo_backup
    exit 1
fi

# ------------------------------------------------------------------------------

set -x

debuild -S -sa "${debuild_args[@]}"

undo_backup

# ------------------------------------------------------------------------------

cd ..

if [ $do_dput -eq 1 ]; then
    dput $UBUNTU_PPA $changes_file
fi

