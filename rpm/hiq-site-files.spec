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

%global pypi_name hiq-site-files

%global py3_prefix /usr/local/hiq
%global py3_sitelib %(%{__python3} -Ic "from distutils.sysconfig import get_python_lib; print(get_python_lib(0, 0, '%{py3_prefix}'))")
%global py3_sitearch %(%{__python3} -Ic "from distutils.sysconfig import get_python_lib; print(get_python_lib(1, 0, '%{py3_prefix}'))")

# ==============================================================================

Name: python-%{pypi_name}
Version: 1.0.0
Release: 0%{?dist}
License: Apache-2.0
URL: https://hiq.huaweicloud.com/en/

BuildArch: noarch

# Disable debug package
%define debug_package %nil

# ==============================================================================

Summary:	Huawei-HiQ fork of ProjectQ
Requires:	python3
Provides:	python-%{pypi_name} = %{version}-%{release}
%{?python_provide:%python_provide python-%{pypi_name}}

BuildRequires:	python3-devel

%description
Site files for all HiQ Python

# ------------------------------------------------------------------------------

%package -n     python3-hiq-site-files
Summary:        %{summary}
Requires:	python3
Provides:	python3-hiq-site-files = %{version}-%{release}
%{?python_provide:%python_provide python3-%{pypi_name}}

BuildRequires:	python3-devel

%description -n python3-hiq-site-files
Site files for all HiQ Python

# ==============================================================================

%prep

%build

%install

# Add sub-directory to python search path
mkdir -p %{buildroot}%{python3_sitelib}
cat << \EOF > %{buildroot}%{python3_sitelib}/hiq-python.pth
%{py3_sitelib}
%{py3_sitearch}
EOF

mkdir -p %{buildroot}%{python3_sitearch}
cat << \EOF > %{buildroot}%{python3_sitearch}/hiq-python.pth
%{py3_sitelib}
%{py3_sitearch}
EOF

# ==============================================================================

%files -n python-%{pypi_name}
%defattr(-,root,root,-)
%{python3_sitelib}/hiq-python.pth
%{python3_sitearch}/hiq-python.pth

%files -n python3-%{pypi_name}
%defattr(-,root,root,-)
%{python3_sitelib}/hiq-python.pth
%{python3_sitearch}/hiq-python.pth

# ==============================================================================

%changelog
* Thu Sep 10 2020 Damien Nguyen <damien1@huawei.com> - 0.6.4.post2-6%{?dist}
- Initial build
