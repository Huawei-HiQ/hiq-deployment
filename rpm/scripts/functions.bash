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

function in_array()
{
    local needle="$1" arrref="$2[@]" item
    for item in "${!arrref}"; do
	[[ "${item}" == "${needle}" ]] && return 0
    done
    return 1
}

# ------------------------------------------------------------------------------

function trim()
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

function get_arch_name()
{
    local arch_name=""
    if [ "$os_name" == "centos" ]; then
	arch_name="el$os_ver"
    elif [ "$os_name" == "fedora" ]; then
	arch_name="fc$os_ver"
    elif [ "$os_name" == "openmandriva" ]; then
	arch_name=omv4050
    elif [ "$os_name" == "opensuse-leap" ]; then
	arch_name="lp$(echo $os_ver | tr -d '.')"
    else
	echo "Unsupported distribution found: $os_name" 1>&2
	exit 1
    fi
    echo $arch_name
}

# ==============================================================================

function capture_rpms()
{
    echo -n '' > /tmp/rpms.txt
    while read line; do
	rpm=$(echo $line | egrep '^Wrote:.*\.rpm$')
	if [ -n "$rpm" ]; then
	    echo "$rpm" | cut -d ' ' -f2 >> /tmp/rpms.txt
	fi
	echo $line
    done
}

# ------------------------------------------------------------------------------

function get_rpms()
{
    local rpms srpms
    pkg=$1

    rpms_raw=$(ls $HERE/rpms/ | egrep "rpm$" | grep -- $arch_name | grep -i $pkg)

    rpms=""
    for rpm in $rpms_raw; do
	rpms="$rpms $HERE/rpms/$rpm"
	deps_list=$(rpm --requires -qp $HERE/rpms/$rpm | cut -d ' ' -f1 | sed 's/(.*)//g' | egrep -v '^python3?$')
	for rpm_deps in $deps_list; do
	    deps=$(ls $HERE/rpms/ | egrep "rpm$" | grep -- $arch_name | egrep ${rpm_deps}-[0-9])
	    if [ -n "$deps" ]; then
		rpms="$rpms $HERE/rpms/$deps"
	    fi
	done
    done

    if [ -n "$rpms" ]; then
	for rpm in $rpms; do
	    rpm=$(basename $rpm)
	    rpm_dir=$(rpmspec --eval '%_rpmdir')
	    mkdir -p $rpm_dir/x86_64/
	    mkdir -p $rpm_dir/noarch/

	    if [[ -n "$(echo $rpm | grep x86_64)" && ! -f $rpm_dir/x86_64/$rpm ]]; then
		/bin/cp -v $HERE/rpms/$rpm $rpm_dir/x86_64/ 1>&2
	    fi
	    if [[ -n "$(echo $rpm | grep noarch)" && ! -f $rpm_dir/noarch/$rpm ]]; then
		/bin/cp -v $HERE/rpms/$rpm $rpm_dir/noarch/ 1>&2
	    fi
	done
    fi

    srpms=$(ls $HERE/srpms/ | egrep "rpm$" | grep -- $arch_name | grep -i $pkg)
    if [ -n "$srpms" ]; then
	srpm_dir=$(rpmspec --eval '%_srcrpmdir')
	mkdir -p $srpm_dir
	/bin/cp -v $HERE/srpms/$srpms $srpm_dir 1>&2
    fi

    echo "$rpms"
}

# ==============================================================================

function pkg_builddep()
{
    src_dir=$(rpmspec --eval '%_sourcedir')
    mkdir -p $src_dir
    if [ "$os_name" == "centos" ]; then
	yum-builddep -y "$@"
    elif [ "$os_name" == "fedora" ]; then
	dnf builddep -y "$@"
    elif [ "$os_name" == "openmandriva" ]; then
	dnf builddep -y "$@"
	sources=$(get_sources "$@" | grep http)
	if [ -n "$sources" ]; then
	    for file in "$sources"; do
		wget -NP "$src_dir" $file
	    done
	fi
    elif [ "$os_name" == "opensuse-leap" ]; then
	deps=$(rpmspec -q "$@" --buildrequires)
	if [ -n "$deps" ]; then
	    zypper install -y $deps
	fi
	sources=$(get_sources "$@" | grep http)
	if [ -n "$sources" ]; then
	    for file in "$sources"; do
		wget -NP "$src_dir" $file
	    done
	fi
    else
	echo "Unsupported distribution found: $os_name"
	exit 1
    fi
}

# ------------------------------------------------------------------------------

function pkg_build()
{
    if [ "$os_name" == "opensuse-leap" ]; then
	rpmbuild -D "dist .$arch_name" "$@"
    else
	rpmbuild "$@"
    fi
}

# ------------------------------------------------------------------------------

function pkg_install()
{
    if [ "$os_name" == "centos" ]; then
	yum install -y "$@"
    elif [["$os_name" == "fedora" || "$os_name" == "openmandriva" ]]; then
	dnf install -y "$@"
    elif [ "$os_name" == "opensuse-leap" ]; then
	local fargs zargs rpm
	fargs=()
	zargs=()
	args="$@"
	for rpm in $args; do
	    if [ -f "$rpm" ]; then
		fargs+=($rpm)
	    else
		zargs+=($rpm)
	    fi
	done

	exclude_cmd=(grep -Fv)
	if [ -n "${fargs[*]}" ]; then
	    for rpm in "${fargs[@]}"; do
		for name in $(rpm --provides -qp $rpm); do
		    exclude_cmd+=(-e "$name")
		done
	    done
	fi
	if [ -n "${zargs}" ]; then
	    rm -rf /tmp/rpms/*
	    zypper --pkg-cache-dir /tmp/rpms install -yd "${zargs[@]}"
	    for rpm in $(find /tmp/rpms/ -name '*.rpm'); do
		fargs+=($rpm)
	    done
	fi
	if [ -n "${fargs[*]}" ]; then
	    tmp=$(rpm --requires -qp "${fargs[@]}" | "${exclude_cmd[@]}")
	    if [ -n "$tmp" ]; then
		zypper install -y $tmp
	    fi
	    rpm -i --force "${fargs[@]}"
	fi
    else
	echo "Unsupported distribution found: $os_name"
	exit 1
    fi
}

# ------------------------------------------------------------------------------

function pkg_copy_patches()
{
    local pkg=$1
    patches=$(ls $root/${pkg}* | grep patch)
    if [ -n "$patches" ];then
	src_dir=$(rpmspec --eval '%_sourcedir')
	mkdir -p $src_dir
	/bin/cp -v $root/$pkg* $src_dir
    fi
}

# ------------------------------------------------------------------------------

function pkg_copy()
{
    local rpms srpms
    rpms=$(cat /tmp/rpms.txt | egrep -v 'src.rpm$')
    srpms=$(cat /tmp/rpms.txt | egrep 'src.rpm$')

    mkdir -p rpms/
    for rpm in $rpms; do
	bname=$(basename $rpm)
	if [ ! -f $HERE/rpms/$bname ]; then
	    /bin/cp -v $rpm $HERE/rpms/
	fi
    done

    mkdir -p srpms/
    for rpm in $srpms; do
	bname=$(basename $rpm)
	if [ ! -f $HERE/srpms/$bname ]; then
	    /bin/cp -v $rpm $HERE/srpms/
	fi
    done
}

# ==============================================================================
