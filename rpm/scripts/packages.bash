# Packages that need to be built first and then installed in order to build the
# others
build=()
if [ "$os_name" == "centos" ]; then
    if [ $os_ver -eq 7 ]; then
	build_and_install=(cython pybind11 numpy scipy cycler kiwisolver qhull matplotlib pandas)
    elif [ $os_ver -eq 8 ]; then
	build_and_install=(cython numpy scipy)
	build+=(openfermion pubchempy networkx sympy pyscf)
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
elif [ "$os_name" == "opensuse-leap" ]; then
    build_and_install=()
    if [ "$os_ver" == "15.1" ]; then
	build_and_install+=(cython numpy pybind11)
	build+=(networkx sympy mpi4py matplotlib)
    elif [ "$os_ver" == "15.2" ]; then
	build_and_install+=(numpy pybind11)
    else
	echo "Unsupported OpenSUSE/leap version: $os_ver"
    fi
    build+=(pubchempy openfermion pyscf)
elif [ "$os_name" == "opensuse-tumbleweed" ]; then
    # Take care of potentially incompatible scipy version for HiQ-Fermion?
    build_and_install=()
    build+=(pubchempy openfermion pyscf)
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi

