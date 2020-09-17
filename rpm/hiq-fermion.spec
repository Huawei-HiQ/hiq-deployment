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

%global hiq_fermion_version 0.0.1
%global hiq_fermion_release 0
%global sha256 62905e9150d603b0f18860da665033e1481565cbd243a413798f2643471c0ea6
%global pypi_name hiq-fermion

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

# ==============================================================================

Name: python-%{pypi_name}
Version: %{hiq_fermion_version}
Release: %{hiq_fermion_release}%{?dist}
License: Apache-2.0
URL: https://hiq.huaweicloud.com/en/
Source0: %{pypi_source}

BuildArch:      noarch

BuildRequires:  python3-devel

# ==============================================================================

%define requirements					\
Requires:	python3-hiq-site-files			\
%if 0%{?rhel} && 0%{?rhel} < 8 				\
# CentOS 7 && CentOS 8					\
Requires:	python36-h5py >= 2.9.0			\
Requires:	python36-numpy >= 1.11			\
Requires:	python36-scipy >= 1.1.0			\
Requires:	python36-pyscf >= 1.6.3			\
%else							\
# Fedora > 30 && CentOS 8				\
Requires:	python3dist(h5py) >= 2.9.0		\
Requires:	python3dist(numpy) >= 1.11.0		\
Requires:	python3dist(pyscf) >= 1.6.3		\
Requires:	python3dist(scipy) >= 1.1.0		\
%endif 				      			\
Requires:       python3-hiq-projectq			\
Requires:       python3-hiq-openfermionprojectq

# ==============================================================================

Summary:	Huawei HiQ sub-project for quantum chemistry.
Provides:	python-%{pypi_name} = %{version}-%{release}
%{?python_provide:%python_provide python-%{pypi_name}}

%requirements

%description
HiQfermion is a module which is comparable with openfermion and implements more
quantum chemistry functions.

# ------------------------------------------------------------------------------

%package -n     python3-%{pypi_name}
Summary:        %{summary}
Provides:	python3-%{pypi_name} = %{version}-%{release}
%{?python_provide:%python_provide python3-%{pypi_name}}

%requirements

%description -n python3-%{pypi_name}
HiQfermion is a module which is comparable with openfermion and implements more
quantum chemistry functions.

# ==============================================================================

%prep
echo "%sha256  %SOURCE0" | sha256sum -c -
%autosetup -n %{pypi_name}-%{version} -p1
# Remove bundled egg-info
rm -rf $(echo %{pypi_name} | tr - _).egg-info

# --------------------------------------

%build
%py3_build

# --------------------------------------

%install

%py3_install -- --prefix %{py3_prefix}

%py_byte_compile %{__python3} %{buildroot}%{py3_sitelib}

# --------------------------------------

%if %{with tests}
%check

%endif

# ==============================================================================

%files -n python3-%{pypi_name}
%defattr(-,root,root,-)
%doc README.md
%{py3_sitelib}/hiq_fermion-%{version}-py%{python3_version}.egg-info
%{py3_sitelib}/hiqfermion
%exclude %{py3_sitelib}/__pycache__

# ==============================================================================

%changelog
* Thu Aug 20 2020 Damien Nguyen <damien1@huawei.com> - 0.6.4.post2-6%{?dist}
- Initial build

