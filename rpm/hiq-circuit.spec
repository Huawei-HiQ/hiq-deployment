%global hiq_circuit_version 0.0.2.post4
%global hiq_circuit_release 0
%global sha256 09cbbba91635bfc7b015fe66af4f46c4ceafb1a936affc98b1c273e4b7bc57ef
%global pypi_name hiq-circuit

# ==============================================================================

Name: python-%{pypi_name}
Version: %{hiq_circuit_version}
Release: %{hiq_circuit_release}%{?dist}
License: Apache-2.0
URL: https://hiq.huaweicloud.com/en/
%undefine _disable_source_fetch
Source0: %{pypi_source}

# Disable debug package
%define debug_package %nil

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:  boost169-openmpi-devel
BuildRequires:	boost169-python3-devel
BuildRequires:  cmake3
BuildRequires:	devtoolset-8-gcc-c++
BuildRequires:  python3-setuptools
%if %{with tests}
BuildRequires:	python36-pytest
%endif
%else
# Fedora > 30 && CentOS > 7
BuildRequires:	boost-openmpi-devel
BuildRequires:	boost-python3-devel
BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  python3dist(setuptools)
%if %{with tests}
BuildRequires:  python3dist(pytest)
%endif
%endif

BuildRequires:  make
BuildRequires:	eigen3-devel
BuildRequires:	gflags-devel
BuildRequires:	glog-devel
BuildRequires:	hwloc-devel
BuildRequires:	lapack-devel
BuildRequires:	openblas-devel
BuildRequires:	openmpi-devel
BuildRequires:  python3-devel

# ==============================================================================

%define requirements				\
%if 0%{?rhel} && 0%{?rhel} < 8			\
# CentOS 7					\
Requires:	devtoolset-8			\
Requires:       mpi4py-openmpi			\
%else						\
# Fedora > 30 && CentOS > 7			\
Requires:     	python3-mpi4py-openmpi		\
%endif						\
						\
%if 0%{?rhel} && 0%{?rhel} < 8			\
# CentOS 7					\
Requires:	boost169-openmpi		\
Requires:	boost169-python3		\
%else						\
# Fedora > 30 && CentOS > 7			\
Requires:	boost-openmpi			\
Requires:	boost-python3			\
%endif						\
Requires:	gflags				\
Requires:	glog				\
Requires:	hwloc				\
Requires:	lapack				\
Requires:	openblas			\
Requires:	openmpi
Requires:	python3

# ==============================================================================

Summary:	A high performance distributed quantum simulator
Provides:	python-%{pypi_name} = %{version}-%{release}
%{?python_provide:%python_provide python-%{pypi_name}}

Requires:       python-hiq-projectq
%requirements

%description
Huawei HiQsimulator Huawei HiQ is an open-source software framework for quantum
computing. It is based on and compatible with ProjectQ <>__. It aims at
providing tools which facilitate inventing, implementing, testing, debugging,
and running quantum algorithms using either classical hardware or actual
quantum devices.

# ------------------------------------------------------------------------------

%package -n     python3-%{pypi_name}
Summary:        %{summary}
Provides: 	python3-%{pypi_name} = %{version}-%{release}
%{?python_provide:%python_provide python3-%{pypi_name}}

Requires:       python3-hiq-projectq
%requirements

%description -n python3-%{pypi_name}
Huawei HiQsimulator Huawei HiQ is an open-source software framework for quantum
computing. It is based on and compatible with ProjectQ <>__. It aims at
providing tools which facilitate inventing, implementing, testing, debugging,
and running quantum algorithms using either classical hardware or actual
quantum devices.

# ==============================================================================

%prep
echo "%sha256  %SOURCE0" | sha256sum -c -
%autosetup -n %{pypi_name}-%{version} -p1
# Remove bundled egg-info
rm -rf %{pypi_name}.egg-info

# --------------------------------------

%build

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
source /etc/profile.d/modules.sh
alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 20 \
	--slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
	--slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
	--slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
	--family cmake
%else
# Fedora > 30 && CentOS > 7
%set_build_flags
source /etc/profile.d/modules.sh
%endif

module load mpi

%if 0%{?rhel} && 0%{?rhel} < 8
scl enable devtoolset-8 -- <<\EOF
%endif

%py3_build

%if %{with tests}
mkdir cmake_build
cd cmake_build
cmake .. -DBUILD_TESTING=ON -DIS_PYTHON_BUILD=1
make -j$(nproc) build_all_tests
%endif


%if 0%{?rhel} && 0%{?rhel} < 8
EOF
%endif

# --------------------------------------

%install	

%py3_install

# --------------------------------------

%if %{with tests}
%check

cd cmake_build
make test

%endif

# ==============================================================================

%define hiq_circuit_files							\
%license LICENSE								\
%doc README.rst									\
%{python3_sitearch}/hiq_circuit-%{version}-py%{python3_version}.egg-info	\
%{python3_sitearch}/hiq								\
%{python3_sitearch}/projectq/__init__.py					\
%{python3_sitearch}/projectq/__pycache__					\
%{python3_sitearch}/projectq/backends/__init__.py				\
%{python3_sitearch}/projectq/backends/__pycache__				\
%{python3_sitearch}/projectq/backends/_hiqsim					\
%{python3_sitearch}/projectq/backends/_resource_counter_mod.py*			\
%{python3_sitearch}/projectq/cengines/__init__.py				\
%{python3_sitearch}/projectq/cengines/__pycache__				\
%{python3_sitearch}/projectq/cengines/_dummybackend.py				\
%{python3_sitearch}/projectq/cengines/_greedyscheduler.py			\
%{python3_sitearch}/projectq/cengines/_hiq_main_engine.py			\
%{python3_sitearch}/projectq/cengines/_merger_engine.py				\
%{python3_sitearch}/projectq/cengines/_noisegenerator.py			\
%{python3_sitearch}/projectq/cengines/_sched_cpp.*.so				\
%{python3_sitearch}/projectq/ops/__init__.py					\
%{python3_sitearch}/projectq/ops/__pycache__					\
%{python3_sitearch}/projectq/ops/_hiq_gates.py

# ------------------------------------------------------------------------------

%files
%defattr(-,root,root,-)
%hiq_circuit_files

%files -n python3-%{pypi_name}
%defattr(-,root,root,-)
%hiq_circuit_files

# ==============================================================================

%changelog
* Thu Aug 20 2020 Damien Nguyen <damien1@huawei.com> - 0.0.2.post4-0%{?dist}
- Initial build
