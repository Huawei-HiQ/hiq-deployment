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
root=$HERE/../

# ==============================================================================

# Requires Bash >= 4
declare -A ubuntu_versions=(["xenial"]="16.04"
			    ["bionic"]="18.04"
			    ["eoan"]="19.10"
			    ["focal"]="20.04"
			    ["groovy"]="20.10")
assume_yes=0
clean_dirs=0
clean_only=0
ubuntu_distro=''
output_dir=''

# ==============================================================================

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
no_arg() {
    if [ -n "$OPTARG" ]; then die "No arg allowed for --$OPT option"; fi; }
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

python_setup() { python3 setup.py $1 2> /dev/null; }

help_message() {
    echo -e '\nUsage:'
    echo "  " `basename $0` "[options] pkg_name [debuild options]"
    echo -e '\nOptions:'
    echo '  -h,--help          Show this help message and exit'
    echo '  -c,--clean         (optional) start from clean folder'
    echo '  --clean-only       (optional) only perform clean step'
    echo '  -d,--distro [rel]  Specify for which Ubuntu distro the package is'
    echo '                     designed for (e.g. xenial, bionic, eoan, focal)'
    echo '  -o,--output [dir]  (optional) Specify output directory for generated'
    echo '                     files'
    echo "                     Defaults to: $root/"
    echo '  -y,--yes           Assume yes to all prompts'
    echo ''
    echo 'Any options passede *after* the package name will be forwarded to'
    echo '`debuild`'
    echo -e '\nExample calls:'
    echo "$0 -d eoan -y hiq-circuit"
    echo "$0 -d xenial -o /tmp/data hiq-projectq -S -sd"
}

# ------------------------------------------------------------------------------

while getopts hcyo:d:-: OPT; do
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi

  case "$OPT" in
      h | help )    no_arg;
		    help_message >&2
		    exit 1 ;;
      c | clean )   no_arg;
		    clean_dirs=1
		    ;;
      clean-only )  no_arg;
		    clean_only=1
		    ;;
      d | distro )  needs_arg;
		    ubuntu_distro=$OPTARG
		    ;;
      o | output )  needs_arg;
		    output_dir=$OPTARG
		    ;;
      y | yes )     no_arg;
		    assume_yes=1
		    ;;
    ??* )           die "Illegal option --OPT: $OPT" ;;
    \? )            exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

# ------------------------------------------------------------------------------

pkg=$1
shift
args=("$@")

# Get Ubuntu distro name and version number
if [ -z "$ubuntu_distro" ]; then
    die "Missing -d,--distro!"
fi
ubuntu_distro_num=${ubuntu_versions[$ubuntu_distro]}
if [ -z "$ubuntu_distro_num" ]; then
    die "Invalid distro name: $ubuntu_distro (allowed values: ${!ubuntu_versions[@]})"
fi

# ==============================================================================

if [ ! -f $HERE/../setup_env.bash ]; then
    die "Missing $HERE/../setup_env.bash"
fi
source $HERE/../setup_env.bash
source $HERE/functions.bash

# ------------------------------------------------------------------------------

if [ -z "$DEBFULLNAME" ]; then
    die "Please define the DEBFULLNAME environment variable (e.g. 'John Doe')"
fi
if [ -z "$DEBEMAIL" ]; then
    die "Please define the DEBEMAIL environment variable (e.g. 'john@example.com')"
fi

if python3 -m pip > /dev/null; then
    :
else
    die "Unable to find the Python pip module!"
fi

# ==============================================================================
# Setup directory

pkg_dir=$(basename $(ls -d $root/debian-templates/* | grep $pkg))
if [ -z "$pkg_dir" ]; then
    die "Missing folder in $root/debian-templates!"
fi

pkg_name=$pkg
pkg_ver=${pkg_dir##$pkg-}

if [ -f $root/_${pkg_name}_config.bash ]; then
    source $root/_${pkg_name}_config.bash
else
    ppa_rev=1
fi

pkg_dir=$root/$pkg_dir

# ------------------------------------------------------------------------------
# Cleanup?

if [ $clean_dirs -eq 1 ]; then
    dir=$root/backup/$(basename $pkg_dir)
    if [ -d $dir ]; then
	echo "Cleaning $dir"
	rm -rf $dir
    fi

    dir=$pkg_dir
    if [ -d $dir ]; then
	echo "Cleaning $dir"
	rm -rf $dir
    fi

    file=${pkg_name}*orig*
    if [ -f $file ]; then
	rm -vf $file
    fi

    if [ $clean_only -eq 1 ]; then
	exit 0
    fi
fi

# ------------------------------------------------------------------------------
# Setup source directory

archive_name=$(pkg_download $pkg_name $pkg_archive_name)
if [ ! -d $pkg_dir ]; then
    echo tar xvf $archive_name -C $root
    tar xvf $archive_name -C $root

    if [ ! -d $pkg_dir ]; then
	if [ -z "$pkg_archive_name" ]; then
	    pkg_archive_name=$pkg_name
	fi
	mv -v $root/${pkg_archive_name}-$pkg_ver $pkg_dir
    fi
fi

# ------------------------------------------------------------------------------
# Setup debian sub-directory

if [ ! -d $pkg_dir/debian ]; then
    cp -rv $root/debian-templates/$(basename $pkg_dir) $pkg_dir/debian
    chown -R --reference=$root/debian-templates $pkg_dir/debian
fi

pkg_prepare $pkg_dir
pkg_apply_patches $pkg_dir

if [ ! -f $pkg_dir/debian/changelog ]; then
    dch -p \
	--create \
	--package $pkg_name \
	-c $pkg_dir/debian/changelog \
	-D unstable \
	-v "${pkg_ver}-1" \
	"For a detailed changelog, please see the GitHub release page or the Pypi" \
	"package page."
fi
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
