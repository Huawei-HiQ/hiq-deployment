%global hiq_projectq_version 0.6.4.post2
%global hiq_projectq_release 6
%global sha256 f404e530cea8a1741062626ca7ebe23e9a3bde1198cd0bf602fde0fe2c9359fe
%global pypi_name hiq-projectq

# ==============================================================================

# This can be used to disable all tests for faster bootstrapping
%bcond_without tests

# ==============================================================================

Name: python-%{pypi_name}
Version: %{hiq_projectq_version}
Release: %{hiq_projectq_release}%{?dist}
License: Apache-2.0
URL: https://hiq.huaweicloud.com/en/
%undefine _disable_source_fetch
Source0: %{pypi_source}

# Disable debug package
%define debug_package %nil

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:  centos-release-scl
BuildRequires:  devtoolset-8
BuildRequires:	devtoolset-8-gcc-c++
BuildRequires:  epel-release
BuildRequires:	python3-setuptools
# NB: pybind11 is installed via pip during %build
# NB: numpy, scipy, sympy are installed via pip during %check
%if %{with tests}
BuildRequires:	python36-numpy
BuildRequires:	python36-scipy
BuildRequires:	python36-requests
BuildRequires:	python36-pytest
# NB: sympy, matplotlib and networkx are installed via pip during %check
%endif
%else
# Fedora > 30 && CentOS > 7
BuildRequires:	gcc-c++
%if 0%{?rhel} == 8
BuildRequires:  epel-release
%endif
BuildRequires:  python3dist(setuptools)
BuildRequires:  python3dist(pybind11)
# NB: pybind11 is installed via pip during %build for CentOS 8
%if %{with tests}
BuildRequires:  python3dist(pytest)
BuildRequires:  python3dist(networkx)
BuildRequires:  python3dist(numpy)
BuildRequires:  python3dist(requests)
BuildRequires:  python3dist(scipy)
%if ! 0%{?rhel}
BuildRequires:  python3dist(matplotlib) >= 2.2.3
BuildRequires:  python3dist(sympy)
%endif
# NB: sympy and matplotlib are installed via pip during %check for CentOS 8
%endif
%endif

BuildRequires:  python3-devel

# ==============================================================================

%define requirements						\
%if 0%{?rhel} && 0%{?rhel} < 8					\
# CentOS 7							\
Requires:	devtoolset-8					\
Requires:       python36-numpy					\
Requires:       python36-scipy					\
Requires:       python36-requests				\
# NB: missing packages: sympy, pybind11, networkx, matplotlib	\
%else								\
# Fedora > 30 && CentOS > 7					\
Requires:       python3dist(matplotlib) >= 2.2.3		\
Requires:       python3dist(networkx)				\
Requires:       python3dist(numpy)				\
Requires:       python3dist(requests)				\
Requires:       python3dist(scipy)				\
%if ! 0%{?rhel}							\
Requires:       python3dist(sympy)				\
%endif								\
# NB: missing sympy package on CentOS 8				\
								\
Conflicts:      python3dist(projectq)				\
%endif

# ==============================================================================

Summary:	Huawei-HiQ fork of ProjectQ
Provides:	python-%{pypi_name} = %{version}-%{release}
%{?python_provide:%python_provide python-%{pypi_name}}

%requirements

%description
ProjectQ - An open source software framework for quantum computing Important
This package offers the same functionality as the official ProjectQ < package.
It is however based on a development version that may contain some
changes/bugfixes in order to better

# ------------------------------------------------------------------------------

%package -n     python3-%{pypi_name}
Summary:        %{summary}
Provides:	python3-%{pypi_name} = %{version}-%{release}
%{?python_provide:%python_provide python3-%{pypi_name}}

%requirements

%description -n python3-%{pypi_name}
ProjectQ - An open source software framework for quantum computing Important
This package offers the same functionality as the official ProjectQ < package.
It is however based on a development version that may contain some
changes/bugfixes in order to better

# ==============================================================================

%prep
echo "%sha256  %SOURCE0" | sha256sum -c -
%autosetup -n %{pypi_name}-%{version} -p1
# Remove bundled egg-info
rm -rf %{pypi_name}.egg-info

# --------------------------------------

%build

%if 0%{?rhel} && 0%{?rhel} < 8
scl enable devtoolset-8 -- <<\EOF
# CentOS 7 does not have a python3-pybind11 package
%{__python3} -m pip install pybind11
%else
%set_build_flags
%endif

%py3_build

%if 0%{?rhel} && 0%{?rhel} < 8
EOF
%endif

# --------------------------------------

%install

%py3_install

# --------------------------------------

%if %{with tests}
%check

cat << \EOF > matplotlibrc
backend: Agg
EOF

# Make sure there is always at least one test to be found by pytest
cat << \EOF > projectq/rpm_test.py
def test_dummy():
    pass
EOF

%if 0%{?rhel}
%{__python3} -m pip install sympy matplotlib
%if 0%{?rhel} < 8
%{__python3} -m pip install networkx
%endif
%endif

%{__python3} -m pytest -p no:warnings projectq

rm -f projectq/rpm_test.py

%endif

# ==============================================================================

%define hiq_projectq_files							\
%license LICENSE								\
%doc README.rst									\
%{python3_sitearch}/hiq_projectq-%{version}-py%{python3_version}.egg-info	\
%{python3_sitearch}/projectq/*.py*						\
%{python3_sitearch}/projectq/__pycache__					\
%{python3_sitearch}/projectq/backends						\
%{python3_sitearch}/projectq/cengines						\
%{python3_sitearch}/projectq/libs						\
%{python3_sitearch}/projectq/meta						\
%{python3_sitearch}/projectq/ops						\
%{python3_sitearch}/projectq/setups						\
%{python3_sitearch}/projectq/tests						\
%{python3_sitearch}/projectq/types

# ------------------------------------------------------------------------------

%files
%defattr(-,root,root,-)
%hiq_projectq_files

%files -n python3-%{pypi_name}
%defattr(-,root,root,-)
%hiq_projectq_files

# ==============================================================================

%changelog
* Thu Aug 20 2020 Damien Nguyen <damien1@huawei.com> - 0.6.4.post2-6%{?dist}
- Initial build
