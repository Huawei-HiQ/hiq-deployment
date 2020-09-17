%global srcname kiwisolver

%if 0%{?rhel} && 0%{?rhel} < 8
%define __python %{__python3}
%else
# Turn off the brp-python-bytecompile automagic
%global _python_bytecompile_extra 0
%endif

%undefine _disable_source_fetch

# Disable debug package
%define debug_package %nil

# ==============================================================================

%global srcname kiwisolver

Name:           python-%{srcname}
Version:        1.1.0
Release:        2%{?dist}
Summary:        A fast implementation of the Cassowary constraint solver

License:        BSD
URL:            https://github.com/nucleic/kiwi
Source0:        https://github.com/nucleic/kiwi/archive/%{version}/%{srcname}-%{version}.tar.gz

%global _description \
Kiwi is an efficient C++ implementation of the Cassowary constraint solving \
algorithm. Kiwi is an implementation of the algorithm based on the seminal \
Cassowary paper. It is *not* a refactoring of the original C++ solver. Kiwi has \
been designed from the ground up to be lightweight and fast.

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:  devtoolset-8
BuildRequires:	devtoolset-8-gcc-c++
%else
# Fedora > 30 && CentOS 8
BuildRequires:  gcc-c++
%endif

%description %{_description}


%package -n     python3-%{srcname}
Summary:        %{summary}
%{?python_provide:%python_provide python3-%{srcname}}

BuildRequires:  python3-devel
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:  python36-setuptools
BuildRequires:  python36-pytest
%else
# Fedora > 30 && CentOS 8
BuildRequires:  python3-setuptools
BuildRequires:  python3-pytest
%endif

%description -n python3-%{srcname} %{_description}


%prep
%autosetup -n kiwi-%{version}

# Remove bundled egg-info
rm -rf %{srcname}.egg-info


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

%install
%py3_install
%py_byte_compile %{__python3} %{buildroot}%{python3_sitearch}


%check
PYTHONPATH="%{buildroot}%{python3_sitearch}" \
    py.test-3 py/tests/


%files -n python3-%{srcname}
%doc README.rst
%license LICENSE
%{python3_sitearch}/%{srcname}.cpython-*.so
%{python3_sitearch}/%{srcname}-%{version}-py?.?.egg-info


%changelog
* Fri Jul 26 2019 Fedora Release Engineering <releng@fedoraproject.org> - 1.1.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_31_Mass_Rebuild

* Thu May 16 2019 Elliott Sales de Andrade <quantum.analyst@gmail.com> - 1.1.0-1
- Update to latest version

* Sat Feb 02 2019 Fedora Release Engineering <releng@fedoraproject.org> - 1.0.1-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_30_Mass_Rebuild

* Sat Jul 14 2018 Fedora Release Engineering <releng@fedoraproject.org> - 1.0.1-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_29_Mass_Rebuild

* Tue Jun 19 2018 Miro Hrončok <mhroncok@redhat.com> - 1.0.1-2
- Rebuilt for Python 3.7

* Sat Feb 03 2018 Elliott Sales de Andrade <quantum.analyst@gmail.com> - 1.0.1-1
- Initial package.
