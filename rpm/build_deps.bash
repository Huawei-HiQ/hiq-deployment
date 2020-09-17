#! /bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

root=$HERE/deps

os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')
arch_name=""
if [ "$os_name" == "centos" ]; then
    arch_name="el$os_ver"
elif [ "$os_name" == "fedora" ]; then
    arch_name="fc$os_ver"
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi

# ==============================================================================

# Packages that need to be built first and then installed in order to build the
# others
build=()
if [ "$os_name" == "centos" ]; then
    if [ $os_ver -eq 7 ]; then
	build_and_install=(cython pybind11 numpy scipy qhull matplotlib pandas)
    elif [ $os_ver -eq 8 ]; then
	build_and_install=(cython numpy scipy)
	build+=(openfermion pubchempy networkx sympy)
    else
	echo "Unsupported CentOS version: $os_ver"
    fi
elif [ "$os_name" == "fedora" ]; then
    if [ $os_ver -lt 32 ]; then
	build_and_install=(cython numpy)
    else
	build_and_install=()
    fi
    build+=(pubchempy openfermion)
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi

# ==============================================================================

builddep()
{
if [ "$os_name" == "centos" ]; then
    yum-builddep -y "$@"
elif [ "$os_name" == "fedora" ]; then
    dnf builddep -y "$@"
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi
}

pkg_install()
{
if [ "$os_name" == "centos" ]; then
    yum install -y "$@"
elif [ "$os_name" == "fedora" ]; then
    dnf install -y "$@"
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi
}

# ------------------------------------------------------------------------------

function in_array()
{
    local needle="$1" arrref="$2[@]" item
    for item in "${!arrref}"; do
        [[ "${item}" == "${needle}" ]] && return 0
    done
    return 1
}

# ------------------------------------------------------------------------------

copy_patches()
{
    pkg=$1
    patches=$(ls $root/${pkg}* | grep patch)
    if [ -n "$patches" ];then
	mkdir -p ~/rpmbuild/SOURCES
	/bin/cp -v $root/$pkg*.patch ~/rpmbuild/SOURCES/
    fi
}

# ------------------------------------------------------------------------------

copy_rpms()
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

# ------------------------------------------------------------------------------

capture_rpms()
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

get_rpms()
{
    local rpms srpms
    pkg=$1

    rpms_raw=$(ls $HERE/rpms/ | egrep "rpm$" | grep $arch_name | grep -i $pkg)

    rpms=""
    for rpm in $rpms_raw; do
	rpms="$rpms $HERE/rpms/$rpm"
	deps_list=$(rpm --requires -qp $HERE/rpms/$rpm | cut -d ' ' -f1 | sed 's/(.*)//g' | egrep -v '^python3?$')
	for rpm_deps in $deps_list; do
	    deps=$(ls $HERE/rpms/ | egrep "rpm$" | grep $arch_name | egrep ${rpm_deps}-[0-9])
	    if [ -n "$deps" ]; then
		rpms="$rpms $HERE/rpms/$deps"
	    fi
	done
    done

    if [ -n "$rpms" ]; then
	for rpm in $rpms; do
	    rpm=$(basename $rpm)
	    mkdir -p ~/rpmbuild/RPMS/x86_64/
	    mkdir -p ~/rpmbuild/RPMS/noarch/

	    if [[ -n "$(echo $rpm | grep x86_64)" && ! -f ~/rpmbuild/RPMS/x86_64/$rpm ]]; then
		/bin/cp $HERE/rpms/$rpm ~/rpmbuild/RPMS/x86_64/
	    fi
	    if [[ -n "$(echo $rpm | grep noarch)" && ! -f ~/rpmbuild/RPMS/noarch/$rpm ]]; then
		/bin/cp $HERE/rpms/$rpm ~/rpmbuild/RPMS/noarch/
	    fi
	done
    fi

    srpms=$(ls $HERE/srpms/ | egrep "rpm$" | grep $arch_name | grep -i $pkg)
    if [ -n "$srpms" ]; then
	mkdir -p ~/rpmbuild/SRPMS
	/bin/cp $HERE/srpms/$srpms ~/rpmbuild/SRPMS/
    fi

    echo "$rpms"
}

# ==============================================================================

rpms=$(ls $HERE/rpms/ | egrep "rpm$" | grep $arch_name)
for rpm in $rpms; do
    mkdir -p ~/rpmbuild/RPMS/x86_64/
    mkdir -p ~/rpmbuild/RPMS/noarch/

    if [[ -n "$(echo $rpm | grep x86_64)" && ! -f ~/rpmbuild/RPMS/x86_64/$rpm ]]; then
	/bin/cp -v $HERE/rpms/$rpm ~/rpmbuild/RPMS/x86_64/
    fi
    if [[ -n "$(echo $rpm | grep noarch)" && ! -f ~/rpmbuild/RPMS/noarch/$rpm ]]; then
	/bin/cp -v $HERE/rpms/$rpm ~/rpmbuild/RPMS/noarch/
    fi
done

srpms=$(ls $HERE/srpms/ | egrep "rpm$" | grep $arch_name)
if [ -n "$srpms" ]; then
    mkdir -p ~/rpmbuild/SRPMS
    for rpm in $srpms; do
	if [ ! -f ~/rpmbuild/SRPMS/$rpm ]; then
	    /bin/cp -v $HERE/srpms/$rpm ~/rpmbuild/SRPMS/
	fi
    done
fi

for pkg in ${build_and_install[@]}; do
    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	builddep $root/${pkg}.spec
	copy_patches $pkg
	rpmbuild -ba $root/${pkg}.spec 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    rpmbuild -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi

	copy_rpms
    fi
    pkg_install $rpms
done

tmp="${build[@]}"
if [[ -n "$tmp" ]]; then
    specs=""
    for pkg in ${build[@]}; do
	specs="$specs $root/${pkg}.spec"
    done
else
    specs=$(ls $root/*.spec)
fi

for spec in $specs; do
    bname=$(basename $spec)
    pkg=${bname/.spec}
    
    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	if ! in_array $pkg build_and_install; then
	    builddep $root/${pkg}.spec
	    copy_patches $pkg
	    rpmbuild -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		rpmbuild -ba $root/${pkg}.spec 2>&1 | capture_rpms
		if [ $? -ne 0 ]; then
		    exit 1
		fi
	    fi
	    
	    copy_rpms
	fi
    fi
done

# ==============================================================================
