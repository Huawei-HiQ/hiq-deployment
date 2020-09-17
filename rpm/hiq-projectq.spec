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

%global hiq_projectq_version 0.6.4.post2
%global hiq_projectq_release 6
%global sha256 f404e530cea8a1741062626ca7ebe23e9a3bde1198cd0bf602fde0fe2c9359fe
%global pypi_name hiq-projectq

%global py3_prefix /usr/local/hiq
%global py3_sitelib %(%{__python3} -Ic "from distutils.sysconfig import get_python_lib; print(get_python_lib(0, 0, '%{py3_prefix}'))")
%global py3_sitearch %(%{__python3} -Ic "from distutils.sysconfig import get_python_lib; print(get_python_lib(1, 0, '%{py3_prefix}'))")

%if 0%{?rhel} && 0%{?rhel} < 8
%define __python %{__python3}
%else
# Turn off the brp-python-bytecompile automagic
%global _python_bytecompile_extra 0
%endif

# Enable automatic download
%undefine _disable_source_fetch

# Disable debug package
%define debug_package %nil

# ==============================================================================

# This can be used to disable all tests for faster bootstrapping
%bcond_without tests
# Remove dependency for python*-hiq-projectq-matplotlib
%global __requires_exclude ^libpng16-cfdb1654\\.so.*$
# Disable binary stripping
%define __strip /bin/true

# ==============================================================================

Name: python-%{pypi_name}
Version: %{hiq_projectq_version}
Release: %{hiq_projectq_release}%{?dist}
License: Apache-2.0
URL: https://hiq.huaweicloud.com/en/
Source0: %{pypi_source}

BuildRequires:  python3-devel
BuildRequires:  pybind11-devel >= 2.2.0
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
# NB: need to have epel-relase and centos-release-scl *already installed*
#     in order to install devtoolset-8.
BuildRequires:  devtoolset-8
BuildRequires:	devtoolset-8-gcc-c++
BuildRequires: 	python3-setuptools
BuildRequires:  python36-pybind11 >= 2.2.0
%else
# Fedora > 30 && CentOS > 7
BuildRequires:	gcc-c++
BuildRequires:  python3dist(setuptools)
BuildRequires:  python3dist(pybind11) >= 2.2.0
%endif

%if %{with tests}
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:	python36-matplotlib >= 2.2.3
BuildRequires:	python36-networkx
BuildRequires:	python36-numpy
BuildRequires:	python36-pytest
BuildRequires:	python36-requests
BuildRequires:	python36-scipy
BuildRequires:	python36-sympy
%else
# Fedora > 30 && CentOS > 7
BuildRequires:  python3dist(matplotlib) >= 2.2.3
BuildRequires:  python3dist(networkx)
BuildRequires:  python3dist(numpy)
BuildRequires:  python3dist(pytest)
BuildRequires:  python3dist(requests)
BuildRequires:  python3dist(scipy)
BuildRequires:  python3dist(sympy)
%endif
%endif

# ==============================================================================

%define requirements						\
Requires:       python3-hiq-site-files				\
%if 0%{?rhel} && 0%{?rhel} < 8					\
# CentOS 7							\
# NB: need to have epel-relase and centos-release-scl		\
#     *already installed* in order to install devtoolset-8.	\
Requires:	devtoolset-8					\
Requires:       python36-matplotlib				\
Requires:       python36-networkx >= 2.0			\
Requires:       python36-numpy					\
Requires:       python36-requests				\
Requires:       python36-scipy					\
Requires:       python36-sympy					\
%else								\
# Fedora > 30 && CentOS > 7					\
Requires:       python3dist(matplotlib) >= 2.2.3		\
Requires:       python3dist(networkx) >= 2.0			\
Requires:       python3dist(numpy)				\
Requires:       python3dist(requests)				\
Requires:       python3dist(scipy)				\
Requires:       python3dist(sympy)				\
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
rm -rf $(echo %{pypi_name} | tr - _).egg-info

# --------------------------------------

%build

%if 0%{?rhel} && 0%{?rhel} < 8
scl enable devtoolset-8 -- <<\EOF
%else
%set_build_flags
%endif

%py3_build

%if 0%{?rhel} && 0%{?rhel} < 8
EOF
%endif

# --------------------------------------

%install

%py3_install -- --prefix %{py3_prefix}

%py_byte_compile %{__python3} %{buildroot}%{py3_sitearch}

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

user_site=$(%{__python3} -m site --user-site)
delete_user_site=0
if [ ! -d "$user_site" ]; then
   delete_user_site=1
   mkdir -p "$user_site"
fi

cat << \EOF > "$user_site/hiq.pth"
%{buildroot}%{py3_sitelib}
%{buildroot}%{py3_sitearch}
EOF

%{__python3} -m pytest -p no:warnings projectq

rm -f projectq/rpm_test.py
if [ $delete_user_site -eq 1 ]; then
   rm -rf "$user_site"
fi
%endif

# ==============================================================================

%files -n python3-%{pypi_name}
%defattr(-,root,root,-)
%license LICENSE
%doc README.rst
%{py3_sitearch}/hiq_projectq-%{version}-py%{python3_version}.egg-info
%{py3_sitearch}/projectq/*.py*
%{py3_sitearch}/projectq/__pycache__
%{py3_sitearch}/projectq/backends
%{py3_sitearch}/projectq/cengines
%{py3_sitearch}/projectq/libs
%{py3_sitearch}/projectq/meta
%{py3_sitearch}/projectq/ops
%{py3_sitearch}/projectq/setups
%{py3_sitearch}/projectq/tests
%{py3_sitearch}/projectq/types
%exclude %{py3_sitelib}/__pycache__
%exclude %{py3_sitearch}/__pycache__

# ==============================================================================

%changelog
* Thu Sep 10 2020 Damien Nguyen <damien1@huawei.com> - 0.6.4.post2-6%{?dist}
- Install all python packages in /usr/local/hiq instead of /usr/

* Tue Sep  8 2020 Damien Nguyen <damien1@huawei.com> - 0.6.4.post2-6%{?dist}
- Add subpackages for (potential) unmet Python dependencies

* Thu Aug 20 2020 Damien Nguyen <damien1@huawei.com> - 0.6.4.post2-6%{?dist}
- Initial build
