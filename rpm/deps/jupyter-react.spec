%global srcname jupyter-react

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

Summary: React component extension for Jupyter Notebooks
Name: python-%{srcname}
Version: 0.1.7
Release: 1
License: MIT
Group: Python
BuildArch: noarch
URL: https://github.com/timbr-io/jupyter-react
Source0: https://github.com/Huawei-HiQ/%{srcname}/archive/%{version}.tar.gz

BuildRequires: python3-devel
BuildRequires: python3-setuptools

%global _description								\
This repo actually has nothing to do with React, but rather is a base class	\
meant for pairing up with JS based front-end UI components (see			\
https://github.com/timbr-io/jupyter-react-js). The only thing in this module	\
is a "Component" class. This class can be created with a "module" name that	\
matches the name of a JS UI component and opens up a line of commuination	\
called an "IPython Comm". Using the comm messages can be pased back and forth	\
and property and actions can be taken as a result of UI interaction.

%description %{_description}

%package -n python3-%{srcname}
Summary: %{summary}
%{?python_provide:%python_provide python3-%{srcname}}

%description -n python3-%{srcname} %{_description}

Python 3 version.

%prep
%autosetup -n %{srcname}-%{version} -p1
# Remove bundled egg-info
rm -rf $(echo %{srcname} | tr - _).egg-info

%build

%py3_build

%install

%py3_install
%{?py_byte_compile:%py_byte_compile %{__python3} %{buildroot}%{python3_sitelib}}

%files
%defattr(-,root,root,-)
%doc
%{python3_sitelib}/jupyter_react-%{version}-py%{python3_version}.egg-info/
%{python3_sitelib}/jupyter_react/

%changelog
* Wed Oct  7 2020 Damien Nguyen <damien1@huawei.com> - react-1
- Initial build.

