# Packages that need to be built first and then installed in order to build the
# others
build=(pybind11)
if [ "$os_name" == "centos" ]; then
    build+=(cmake)
    if [ "$os_ver" == "stream" ]; then
	build_and_install=(cython pybind11 numpy scipy)
    elif [ $os_ver -eq 7 ]; then
	build_and_install=(cython pybind11 numpy scipy cycler kiwisolver qhull matplotlib pandas)
    elif [ $os_ver -eq 8 ]; then
	build_and_install=(cython pybind11 numpy scipy)
    else
	echo "Unsupported CentOS version: $os_ver"
    fi
    build+=(openfermion pubchempy networkx sympy pyscf)
elif [ "$os_name" == "fedora" ]; then
    if [ $os_ver -lt 32 ]; then
	build_and_install=(cython numpy)
    elif [ $os_ver -lt 34 ]; then
        build+=(cmake)
    else
	build_and_install=()
    fi
    build+=(pubchempy openfermion jupyter-react)
elif [ "$os_name" == "opensuse-leap" ]; then
    build+=(cmake)
    build_and_install=()
    if [ "$os_ver" == "15.1" ]; then
	build_and_install+=(cython numpy pybind11)
	build+=(networkx sympy mpi4py matplotlib)
    elif [ "$os_ver" == "15.2" ]; then
	build_and_install+=(numpy pybind11)
	build+=(matplotlib)
    else
	echo "Unsupported OpenSUSE/leap version: $os_ver"
    fi
    build+=(pubchempy openfermion pyscf jupyter-react)
elif [ "$os_name" == "opensuse-tumbleweed" ]; then
    # Take care of potentially incompatible scipy version for HiQ-Fermion?
    build_and_install=()
    build+=(pubchempy openfermion pyscf jupyter-react)
else
    echo "Unsupported distribution found: $os_name"
    exit 1
fi

