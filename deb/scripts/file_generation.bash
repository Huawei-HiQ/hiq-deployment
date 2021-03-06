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

# Some variables are expected to be defined before sourcing this file:
#  - pkg_name
#  - pkg_ver
#  - DEBFULLNAME
#  - DEBEMAIL
#
# These may be used by the function defined in this file.

# ==============================================================================

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

# ------------------------------------------------------------------------------

gen_version()
{
    ubuntu_num=$1
    version=$(dpkg-parsechangelog -c 1 | grep Version | cut -d ':' -f2 | trim)
    version=$(echo $version | sed -e 's/-[0-9]\+ubuntu[0-9]\+~ubuntu[0-9][0-9].[0-9][0-9]//')
    echo "$version-1ubuntu$ubtu_ver_rev~ubuntu$ubuntu_num"
}


# Requires a single argument: destination_file
gen_changelog()
{
    cat << EOF > $1
$pkg_name ($pkg_ver) unstable; urgency=medium

  * For a detailed changelog, please see the GitHub release page or the Pypi
    package page.
    .
    https://github.com/Huawei-HiQ
    https://pypi.org/project/$pkg_name

 -- $DEBFULLNAME <$DEBEMAIL>  $(date -R)
EOF
}

# ------------------------------------------------------------------------------

gen_changelog()
{
}

# ==============================================================================

# Requires a single argument: destination_file
gen_watch()
{
    cat << EOF > $1
version=4
https://pypi.debian.net/$pkg_name/$pkg_name-(.+)\.(?:zip|tgz|tbz|txz|(?:tar\.(?:gz|bz2|xz)))
EOF
}

# ==============================================================================

# Requires a single argument: destination_file
gen_compat()
{
    cat << EOF > $1
11
EOF
}

# ==============================================================================
