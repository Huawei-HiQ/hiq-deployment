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

%global hiq_pulse_version 1.9.9.dev0
%global hiq_pulse_release 0
%global sha256 XXXXXXXXXXXXXXXX
%global pypi_name hiq-pulse

%global py3_prefix /usr/local/hiq
%global py3_sitelib %(%{__python3} -Ic "from distutils.sysconfig import get_python_lib; print(get_python_lib(0, 0, '%{py3_prefix}'))")
%global py3_sitearch %(%{__python3} -Ic "from distutils.sysconfig import get_python_lib; print(get_python_lib(1, 0, '%{py3_prefix}'))")

%if 0%{?rhel} && 0%{?rhel} < 8
%define __python %{__python3}
%else
%if 0%{?py_byte_compile}
# Turn off the brp-python-bytecompile automagic
%global _python_bytecompile_extra 0
%endif
%endif

# Enable automatic download
%undefine _disable_source_fetch

# Disable debug package
%define debug_package %nil

# ==============================================================================

# This can be used to disable all tests for faster bootstrapping
%bcond_without tests

# ==============================================================================

Name: python-%{pypi_name}
Version: %{hiq_pulse_version}
Release: %{hiq_pulse_release}%{?dist}
License: Apache-2.0
URL: https://hiq.huaweicloud.com/en/
Source0: https://files.pythonhosted.org/packages/source/h/%{pypi_name}/%{pypi_name}-%{version}.tar.gz

BuildRequires:  python3-devel
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
# NB: need to have epel-relase and centos-release-scl *already installed*
#     in order to install devtoolset-8.
BuildRequires:  cmake3
BuildRequires:  devtoolset-8
BuildRequires:	devtoolset-8-gcc-c++
BuildRequires: 	python3-setuptools
%else
BuildRequires:  cmake
BuildRequires:	gcc-c++
%if 0%{?is_opensuse}
# OpenSUSE/leap 15.1 & 15.2
BuildRequires:  python3-setuptools
%else
# Fedora > 30 && CentOS > 7
BuildRequires:  python3dist(setuptools)
%endif
%endif
BuildRequires:  make
BuildRequires:  pybind11-devel >= 2.2.0

# ==============================================================================

%define requirements					\
Requires:	python3-hiq-site-files			\
%if 0%{?rhel} && 0%{?rhel} < 8 				\
# CentOS 7 && CentOS 8					\
Requires:	python36-numpy >= 1.11			\
Requires:	python36-scipy < 1.5.0			\
Requires:	python36-matplotlib			\
Requires:	python36-pybind11 > 2.2.0		\
%else							\
%if 0%{?is_opensuse}					\
# OpenSUSE/leap 15.1 & 15.2				\
Requires:	python3-numpy				\
Requires:	python3-scipy < 1.5.0			\
Requires:	python3-matplotlib			\
Requires:	python3-pybind11 > 2.2.0		\
%else							\
# Fedora > 30 && CentOS 8				\
Requires:	python3dist(numpy)			\
Requires:	python3dist(scipy) < 1.5.0		\
Requires:	python3dist(matplotlib)			\
Requires:	python3dist(pybind11) > 2.2.0		\
%endif				      			\
%endif 				      			\
Requires:       python3-hiq-projectq

%global _description \
Huawei HiQ is an open-source software framework for quantum optimal control.\
You can find more about Huawei HiQ at http://hiq.huaweicloud.com/\
\
The Huawei HiQPulse is a part of Huawei HiQ, includes a pulse library and\
an optimal control algorithm library.

# ==============================================================================

Summary:	Huawei HiQ sub-project for quantum chemistry.
Provides:	python-%{pypi_name} = %{version}-%{release}
%{?python_provide:%python_provide python-%{pypi_name}}

%requirements

%description %_description

# ------------------------------------------------------------------------------

%package -n     python3-%{pypi_name}
Summary:        %{summary}
Provides:	python3-%{pypi_name} = %{version}-%{release}
%{?python_provide:%python_provide python3-%{pypi_name}}

%requirements

%description -n python3-%{pypi_name} %_description

# ------------------------------------------------------------------------------

%package -n     python3-%{pypi_name}-examples
Summary:        %{summary}
Requires:	python3-%{pypi_name} = %{version}-%{release}
Provides:	python3-%{pypi_name}-examples = %{version}-%{release}
%{?python_provide:%python_provide python3-%{pypi_name}-examples}

%requirements

%description -n python3-%{pypi_name}-examples
HiQ-Pulse examples

# ==============================================================================

%prep
echo "%sha256  %SOURCE0" | sha256sum -c -
%autosetup -n %{pypi_name}-%{version} -p1
# Remove bundled egg-info
rm -rf $(echo %{pypi_name} | tr - _).egg-info

# --------------------------------------

%build
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 20 \
	--slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
	--slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
	--slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
	--family cmake
%else
%if 0%{?is_opensuse}
%global _openmpi_load \
 . /etc/profile.d/modules.sh; \
 module load gnu-openmpi;
%global _openmpi_unload  \
 . /etc/profile.d/modules.sh; \
 module unload gnu-openmpi;
%else
%if ! 0%{?is_opensuse}
# Fedora > 30 && CentOS > 7
%set_build_flags
%endif
%endif
%endif

%{_openmpi_load}

%if 0%{?rhel} && 0%{?rhel} < 8
scl enable devtoolset-8 -- <<\EOF
%endif

%py3_build

%if 0%{?rhel} && 0%{?rhel} < 8
EOF
%endif

%{_openmpi_unload}

# --------------------------------------

%install

%if 0%{?is_opensuse}
%global _prefix %{py3_prefix}
%py3_install
%else
%py3_install -- --prefix %{py3_prefix}
%endif

%{?py_byte_compile:%py_byte_compile %{__python3} %{buildroot}%{py3_sitearch}}

# Try to get rid of pyc files, which aren't useful for documentation
find examples/ -name '*.py[co]' -print -delete

# --------------------------------------

%if %{with tests}
%check

%endif

# ==============================================================================

%files -n python3-%{pypi_name}
%license LICENSE
%doc README.md README.rst
%{py3_sitearch}/HiQPulse-%{version}.dist-info
%{py3_sitearch}/hiqpulse
%{py3_sitearch}/hiqpulse_contrib
%exclude %{py3_sitearch}/__pycache__

%files -n python3-%{pypi_name}-examples
%doc examples/*

# ==============================================================================

%changelog
* Thu Sep 17 2020 Damien Nguyen <damien1@Nhuawei.com> - 1.9.9.dev0-0%{?dist}
- Initial build

