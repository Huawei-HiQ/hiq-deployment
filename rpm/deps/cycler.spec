%global srcname cycler
%global sum Cycle through lists in various ways (used by matplotlib)
%global desc General purpose library used by matplotlib to cycle through lists for colors,\
marker styles, etc

%if 0%{?rhel} && 0%{?rhel} < 8
%define __python %{__python3}
%else
%if 0%{?py_byte_compile}
# Turn off the brp-python-bytecompile automagic
%global _python_bytecompile_extra 0
%endif
%endif

%undefine _disable_source_fetch

# Disable debug package
%define debug_package %nil

# ==============================================================================

Name:           python-%{srcname}
Version:        0.10.0
Release:        16%{?dist}
Summary:        %{sum}

License:        BSD
Source0:        https://github.com/matplotlib/cycler/archive/v%{version}/%{name}-%{version}.tar.gz#/%{srcname}-%{version}.tar.gz
URL:            https://github.com/matplotlib/cycler.git

BuildArch:      noarch

%description
%{desc}

%package -n python3-%{srcname}
Summary:        %{sum}
BuildRequires:  python3-devel
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
Requires:       python36-six
BuildRequires:  python36-six
BuildRequires:  python36-setuptools
BuildRequires:  python36-nose
%else
# Fedora > 30 && CentOS 8
Requires:       python3-six
BuildRequires:  python3-six
BuildRequires:  python3-setuptools
BuildRequires:  python3-nose
%endif


%{?python_provide:%python_provide python3-%{srcname}}

%description -n python3-%{srcname}
%{desc}

%prep
%autosetup -n %{srcname}-%{version}

%build
%py3_build

%install
%py3_install
%{?py_byte_compile:%py_byte_compile %{__python3} %{buildroot}%{python3_sitelib}}

%check
%{__python3} setup.py test

%files -n python3-%{srcname}
%doc README.rst
%license LICENSE
%{python3_sitelib}/%{srcname}.py
%{python3_sitelib}/__pycache__/%{srcname}.*.pyc
%{python3_sitelib}/%{srcname}-*.egg-info/

%changelog
* Wed Jul 29 2020 Fedora Release Engineering <releng@fedoraproject.org> - 0.10.0-16
- Rebuilt for https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild

* Sun May 24 2020 Miro Hrončok <mhroncok@redhat.com> - 0.10.0-15
- Rebuilt for Python 3.9

* Thu Jan 30 2020 Fedora Release Engineering <releng@fedoraproject.org> - 0.10.0-14
- Rebuilt for https://fedoraproject.org/wiki/Fedora_32_Mass_Rebuild

* Thu Oct 24 2019 Miro Hrončok <mhroncok@redhat.com> - 0.10.0-13
- Subpackage python2-cycler has been removed
  See https://fedoraproject.org/wiki/Changes/Mass_Python_2_Package_Removal

* Thu Oct 03 2019 Miro Hrončok <mhroncok@redhat.com> - 0.10.0-12
- Rebuilt for Python 3.8.0rc1 (#1748018)

* Sun Aug 18 2019 Miro Hrončok <mhroncok@redhat.com> - 0.10.0-11
- Rebuilt for Python 3.8

* Fri Jul 26 2019 Fedora Release Engineering <releng@fedoraproject.org> - 0.10.0-10
- Rebuilt for https://fedoraproject.org/wiki/Fedora_31_Mass_Rebuild

* Sat Feb 02 2019 Fedora Release Engineering <releng@fedoraproject.org> - 0.10.0-9
- Rebuilt for https://fedoraproject.org/wiki/Fedora_30_Mass_Rebuild

* Fri Jul 13 2018 Fedora Release Engineering <releng@fedoraproject.org> - 0.10.0-8
- Rebuilt for https://fedoraproject.org/wiki/Fedora_29_Mass_Rebuild

* Tue Jun 19 2018 Miro Hrončok <mhroncok@redhat.com> - 0.10.0-7
- Rebuilt for Python 3.7

* Fri Feb 09 2018 Fedora Release Engineering <releng@fedoraproject.org> - 0.10.0-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Tue Jan 16 2018 Iryna Shcherbina <ishcherb@redhat.com> - 0.10.0-5
- Update Python 2 dependency declarations to new packaging standards
  (See https://fedoraproject.org/wiki/FinalizingFedoraSwitchtoPython3)

* Thu Jul 27 2017 Fedora Release Engineering <releng@fedoraproject.org> - 0.10.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Sat Feb 11 2017 Fedora Release Engineering <releng@fedoraproject.org> - 0.10.0-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild

* Tue Dec 13 2016 Stratakis Charalampos <cstratak@redhat.com> - 0.10.0-2
- Rebuild for Python 3.6

* Mon Aug 29 2016 Neal Becker <nbecker@nbecker2> - 0.10.0-1
- Update to 0.10.0

* Tue Jul 19 2016 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.9.0-8
- https://fedoraproject.org/wiki/Changes/Automatic_Provides_for_Python_RPM_Packages

* Thu Feb 04 2016 Fedora Release Engineering <releng@fedoraproject.org> - 0.9.0-7
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Sun Nov 15 2015 Neal Becker <ndbecker2@gmail.com> - 0.9.0-6
- Add BR python-nose

* Sun Nov 15 2015 Neal Becker <ndbecker2@gmail.com> - 0.9.0-5
- rebuild for py3.5

* Fri Nov  6 2015 Neal Becker <ndbecker2@gmail.com> - 0.9.0-3
- fix license

* Fri Oct 30 2015 Neal Becker <ndbecker2@gmail.com> - 0.9.0-1
- init
