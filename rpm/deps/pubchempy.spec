%global srcname PubChemPy

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

Name:           python-%{srcname}
Version:        1.0.4
Release:        1%{?dist}
Summary:        A simple Python wrapper around the PubChem PUG REST API.

License:        BSD
URL:            https://pubchempy.readthedocs.io/
Source0:	https://files.pythonhosted.org/packages/source/P/%{srcname}/%{srcname}-%{version}.tar.gz

BuildArch:      noarch

%global _description %{expand:
PubChemPy is a wrapper around the PubChem PUG REST API that provides a way to
interact with PubChem in Python. It allows chemical searches (including by
name, substructure and similarity), chemical standardization, conversion
between chemical file formats, depiction and retrieval of chemical properties.}

%description %_description

%package -n python3-%{srcname}
Summary:        Python library providing high-performance data analysis tools
BuildRequires:  python3-devel
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:  python36-pandas
BuildRequires:  python36-setuptools
%else
# Fedora > 30 && CentOS 8 && OpenSUSE
BuildRequires:  python3-pandas
BuildRequires:  python3-setuptools
%endif

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
Requires:       python36
Requires: 	python36-pandas
%else
# Fedora > 30 && CentOS 8 && OpenSUSE
Requires:       python3
Requires:	python3-pandas
%endif

%{?python_provide:%python_provide python3-%{srcname}}

%description -n python3-%{srcname} %_description

%prep
%autosetup -n %{srcname}-%{version} -p1

%build
%py3_build

%install
%py3_install

%{?py_byte_compile:%py_byte_compile %{__python3} %{buildroot}%{python3_sitelib}}

%files -n python3-%{srcname}
%defattr(-,root,root,-)
%{python3_sitelib}/PubChemPy-%{version}-py%{python3_version}.egg-info
%{python3_sitelib}/pubchempy.py
%exclude %{python3_sitelib}/__pycache__


%changelog
* Mon Sep 14 2020 Damien Nguyen <damien1@huawei.com> - pubchempy-1
- Initial build.

