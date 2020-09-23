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

%global hiq_projectq_cxx_version 1.0.0
%global hiq_projectq_cxx_release 0
%global sha256 XXXXXXXXXX
%global pypi_name hiq-projectqcxx

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

Name: python-%{pypi_name}
Version: %{hiq_projectq_cxx_version}
Release: %{hiq_projectq_cxx_release}%{?dist}
License: Apache-2.0
URL: https://hiq.huaweicloud.com/en/
Source0: https://files.pythonhosted.org/packages/source/h/%{pypi_name}/%{pypi_name}-%{version}.tar.gz

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:  cmake3
BuildRequires:	devtoolset-8-gcc-c++
BuildRequires:  python3-setuptools
%if %{with tests}
BuildRequires:	python36-pytest
%endif
%else
# Fedora > 30 && CentOS > 7
BuildRequires:  cmake
BuildRequires:  gcc-c++
%if 0%{?is_opensuse}
# OpenSUSE/leap 15.1 & 15.2
BuildRequires:  python3-setuptools
%if %{with tests}
BuildRequires:  python3-pytest
%endif
%else
BuildRequires:  python3dist(setuptools)
%if %{with tests}
BuildRequires:  python3dist(pytest)
%endif
%endif
%endif

BuildRequires:  make
BuildRequires:  python3-devel

# ==============================================================================

%define requirements				\
%if 0%{?rhel} && 0%{?rhel} < 8			\
# CentOS 7					\
Requires:	devtoolset-8			\
%endif						\
Requires:	python3				\
Requires:       python3-hiq-site-files		\
Requires:       python3-hiq-projectq

%global _description \
C++ processing backend for HiQ-ProjectQ

# ==============================================================================

Summary:	C++ processing backend for HiQ-ProjectQ
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
alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 20 \
	--slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
	--slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
	--slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
	--family cmake
%else
%if 0%{?is_opensuse}
# Fedora > 30 && CentOS > 7
%set_build_flags
%endif
%endif

%if 0%{?rhel} && 0%{?rhel} < 8
scl enable devtoolset-8 -- <<\EOF
%endif

%py3_build

# %if %{with tests}
# mkdir -p cmake_build
# cd cmake_build
# cmake .. -DBUILD_TESTING=ON -DIS_PYTHON_BUILD=1
# make -j$(nproc) build_all_tests
# %endif

%if 0%{?rhel} && 0%{?rhel} < 8
EOF
%endif

# --------------------------------------

%install

%if 0%{?is_opensuse}
%global _prefix %{py3_prefix}
%py3_install
%else
%py3_install -- --prefix %{py3_prefix}
%endif

%{?py_byte_compile:%py_byte_compile %{__python3} %{buildroot}%{py3_sitearch}}

# --------------------------------------

%if %{with tests}
%check

# cd cmake_build
# make test

cat << \EOF > matplotlibrc
backend: Agg
EOF

# Make sure there is always at least one test to be found by pytest
mkdir -p tests
cat << \EOF > tests/rpm_test.py
def test_dummy():
    pass
EOF

%{__python3} -m pytest -p no:warnings tests

rm -f tests/rpm_test.py

%endif

# ==============================================================================

%files -n python3-%{pypi_name}
%defattr(-,root,root,-)
%license LICENSE
%doc README.rst
%{py3_sitearch}/hiq_projectqcxx-%{version}-py%{python3_version}.egg-info
%{py3_sitearch}/projectq/__pycache__
%exclude %{py3_sitearch}/projectq/__init__.py
%exclude %{py3_sitearch}/projectq/__pycache__/__init__*
%{py3_sitearch}/projectq/backends/__pycache__
%exclude %{py3_sitearch}/projectq/backends/__init__.py
%exclude %{py3_sitearch}/projectq/backends/__pycache__/__init__*
%{py3_sitearch}/projectq/backends/_cpp2python_bridge.py
%{py3_sitearch}/projectq/backends/_cppresource_counter*.so
%{py3_sitearch}/projectq/cengines/__pycache__
%exclude %{py3_sitearch}/projectq/cengines/__init__.py
%exclude %{py3_sitearch}/projectq/cengines/__pycache__/__init__*
%{py3_sitearch}/projectq/cengines/_cpp2python_bridge.py
%{py3_sitearch}/projectq/cengines/*.so
%{py3_sitearch}/projectq/cengines/_cppmain.py
%{py3_sitearch}/projectq/cengines/_customgate.py
%{py3_sitearch}/projectq/cengines/_py2cpp.py

# ==============================================================================

%changelog
* Thu Sep 17 2020 Damien Nguyen <damien1@huawei.com> - 1.0.0-0%{?dist}
- Initial build
