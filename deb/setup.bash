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

pkg_name=''

# ==============================================================================

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
no_arg() {
    if [ -n "$OPTARG" ]; then die "No arg allowed for --$OPT option"; fi; }
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

python_setup() { python3 setup.py $1 2> /dev/null; }

help_message() {
    echo -e '\nUsage:'
    echo "  " `basename $0` "[options] dest_dir"
    echo -e '\nOptions:'
    echo '  -h,--help     Show this help message and exit'
    echo '  --projectq    Select HiQ-ProjectQ'
    echo '  --circuit     Select HiQ-Circuit (HiQSimulator)'
    echo -e '\nExample calls:'
    echo "$0 --projectq"
    echo "$0 --circuit /tmp/dst_dir"
}

# ------------------------------------------------------------------------------

while getopts h-: OPT; do
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi

  case "$OPT" in
      h | help )    no_arg;
		    help_message >&2
		    exit 1 ;;
      projectq )    no_arg;
		    pkg_name=hiq-projectq
		    ;;
      circuit )     no_arg;
		    pkg_name=hiq-circuit
		    ;;
    ??* )           die "Illegal option --OPT: $OPT" ;;
    \? )            exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

# ==============================================================================

if [ $# -lt 1 ]; then
    dst_dir=$PWD
else
    dst_dir=$1
    shift
fi

if [ -z "$pkg_name" ]; then
    die "Missing one of --projectq, --circuit"
fi

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

if [ ! -d $dst_dir ]; then
    mkdir -pv $dst_dir
fi

cd $dst_dir

if python3 -m pip download $pkg_name --no-deps; then
    pkg_targz=$(ls $pkg_name-*.tar.gz | sort | tail -n1)
    pkg_ver=${pkg_targz/$pkg_name-}
    pkg_ver=${pkg_ver/.tar.gz}
else
    die "Failed to download the source archive for $pkg_name!"
fi

# ------------------------------------------------------------------------------

tar zxf $pkg_targz

root_dir=${pkg_name}-${pkg_ver}
if [ ! -d $root_dir ]; then
    die "Unable to find the following directory after unpacking: $pkg_name-$pkg_ver"
fi

cp -rv $HERE/debian-templates/$pkg_name $root_dir/debian
ln -s $pkg_targz ${pkg_name}_${pkg_ver}.orig.tar.gz

# ------------------------------------------------------------------------------

echo 'Modifying the changelog with:'
echo "  - package name:     $pkg_name"
echo "  - package version:  $pkg_ver"
echo "  - maintainer name:  $DEBFULLNAME"
echo "  - maintainer email: $DEBEMAIL"

source $HERE/scripts/file_generation.bash

gen_changelog $root_dir/debian/changelog
gen_compat    $root_dir/debian/compat
gen_watch     $root_dir/debian/watch

# ==============================================================================
