#! /bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

root=$HERE

os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')

arch_name=""
py=3
if [ "$os_name" == "centos" ]; then
    arch_name="el$os_ver"
    if [ $os_ver -eq 7 ]; then
	py=36
    elif [ $os_ver -eq 8 ]; then
	:
    else
	echo "Unsupported CentOS version: $os_ver"
    fi
elif [ "$os_name" == "fedora" ]; then
    arch_name="fc$os_ver"
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

copy_patches()
{
    local rpms srpms pkg
    pkg=$1
    patches=$(ls $root/${pkg}* | grep patch)
    if [ -n "$patches" ];then
	mkdir -p ~/rpmbuild/SOURCES
	/bin/cp -v $root/$pkg*.patch ~/rpmbuild/SOURCES/
    fi
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
    local rpms srpms pkg
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

hiq_fermion_deps=(python$py-openfermion)

# ==============================================================================

build_hiq_site_files()
{
    pkg=hiq-site-files
    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	builddep $root/${pkg}.spec
	copy_patches $pkg
	rpmbuild -ba ${pkg}.spec --without=tests 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    rpmbuild -ba $root/${pkg}.spec --without=tests  2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi
	copy_rpms
    fi
}

install_hiq_site_files()
{
    pkg=hiq-site-files
    
    build_hiq_site_files
    rpms=$(get_rpms $pkg)
    pkg_install $rpms
}

# ------------------------------------------------------------------------------

build_hiq_projectq()
{
    install_hiq_site_files
    
    pkg=hiq-projectq
    deps=(python$py-matplotlib python$py-networkx python$py-numpy
	  python$py-requests python$py-pytest python$py-scipy
	  python$py-sympy python$py-hiq-site-files
	  # Need to manually take care of the dependencies of the dependencies
	  python$py-cycler python$py-kiwisolver python$py-decorator
	  python$py-mpmath)

    args=()
    for pkg_deps in ${deps[@]}; do
	pkg_name=${pkg_deps/python$py-}

	rpms=$(get_rpms $pkg_name)
	if [ -n "$rpms" ]; then
	    for rpm in "$rpms"; do
		args+=($rpm)
	    done
	else
	    args+=($pkg_deps)
	fi
    done
    yum install -y "${args[@]}"

    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	builddep $root/${pkg}.spec
	if [ $? -ne 0 ]; then
	    exit 1
	fi
	copy_patches $pkg
	rpmbuild -ba ${pkg}.spec 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    rpmbuild -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi
	copy_rpms
    fi
}

install_hiq_projectq()
{
    pkg=hiq-projectq
    
    build_hiq_projectq
    rpms=$(get_rpms $pkg)
    pkg_install $rpms
}

# ------------------------------------------------------------------------------

build_hiq_circuit()
{
    install_hiq_site_files
    
    pkg=hiq-circuit

    deps=(mpi4py-common python$py-mpi4py-openmpi python$py-hiq-site-files)

    args=()
    for pkg_deps in ${deps[@]}; do
	pkg_name=${pkg_deps/python$py-}

	rpms=$(get_rpms $pkg_name)
	if [ -n "$rpms" ]; then
	    for rpm in "$rpms"; do
		args+=($rpm)
	    done
	else
	    args+=($pkg_deps)
	fi
    done
    yum install -y "${args[@]}"

    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	builddep $root/${pkg}.spec
	if [ $? -ne 0 ]; then
	    exit 1
	fi
	copy_patches $pkg
	rpmbuild -ba ${pkg}.spec 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    rpmbuild -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi
	copy_rpms
    fi
}

install_hiq_circuit()
{
    pkg=hiq-circuit
    
    install_hiq_projectq
    build_hiq_circuit
    rpms=$(get_rpms $pkg)
    pkg_install $rpms
}

# ------------------------------------------------------------------------------

build_hiq_fermion()
{
    install_hiq_site_files

    mkdir -p ~/rpmbuild/SOURCES
    cp -v hiq-fermion-0.0.1.tar.gz ~/rpmbuild/SOURCES
    pkg=hiq-fermion
    rpms=$(get_rpms $pkg)
    if [ -z "$rpms" ]; then
	builddep $root/${pkg}.spec
	if [ $? -ne 0 ]; then
	    exit 1
	fi
	copy_patches $pkg
	rpmbuild -ba ${pkg}.spec 2>&1 | capture_rpms
	if [ $? -ne 0 ]; then
	    rpmbuild -ba $root/${pkg}.spec 2>&1 | capture_rpms
	    if [ $? -ne 0 ]; then
		exit 1
	    fi
	fi
	copy_rpms
    fi
}

install_hiq_fermion()
{
    install_hiq_projectq
    
    deps=(python$py-h5py python$py-numpy python$py-scipy python$py-pyscf
	  python$py-openfermion python$py-openfermionprojectq)
    
    args=()
    for pkg in ${deps[@]}; do
	pkg_name=${pkg/python$py-}

	rpms=$(ls ~/rpmbuild/RPMS/*/* | grep -i $pkg_name)
	if [ -n "$rpms" ]; then
	    for rpm in "$rpms"; do
		args+=($rpm)
	    done
	else
	    args+=($pkg)
	fi
    done
    yum install -y "${args[@]}"

    build_hiq_fermion
    rpms=$(ls ~/rpmbuild/RPMS/*/* | grep -i hiq-fermion)
    pkg_install $rpms
}

# ==============================================================================

build_hiq_projectq
build_hiq_circuit
build_hiq_fermion

