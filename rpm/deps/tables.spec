%if 0%{?rhel} && 0%{?rhel} < 8
%define __python %{__python3}
%else
%if 0%{?py_byte_compile}
# Turn off the brp-python-bytecompile automagic
%global _python_bytecompile_extra 0
%endif
%endif

%if 0%{?is_opensuse}
%global python3_pkgversion 3
%elif 0%{?mdkver}
%global python3_pkgversion %{nil}
%endif

# Enable automatic download
%undefine _disable_source_fetch

# Disable debug package
%define debug_package %nil

%global srcname pandas

# ==============================================================================

#global commit 16191801a53eddae8ca9380a28988c3b5b263c5e
%{?gitcommit:%global gitcommitshort %(c=%{gitcommit}; echo ${c:0:7})}

# Use the same directory of the main package for subpackage licence and docs
%global _docdir_fmt %{name}

Summary:        HDF5 support in Python
Name:           python-tables
Version:        3.6.1
Release:        3%{?dist}%{?gitcommit:.git%{shortcommit}}
#Source0:        https://github.com/PyTables/PyTables/archive/%{commit}/PyTables-%{commit}.tar.gz
Source0:        https://github.com/PyTables/PyTables/archive/v%{version}/python-tables-%{version}.tar.gz

# sometimes it doesn't get updated
%global manual_version 3.3.0

Source1:        https://github.com/PyTables/PyTables/releases/download/v%{manual_version}/pytablesmanual-%{manual_version}.pdf
Patch0:         tables-always-use-blosc.diff
Patch1:         tables-0001-Skip-tests-that-fail-on-s390x.patch
Patch2:         tables-0001-doctest-adjust-__init__-TypeError-formatting.patch
Patch3:         tables-0001-Use-lowercase-float64-as-numpy-dtype.patch
Patch4:         tables-0001-Fix-syntax-warnings.patch

License:        BSD
URL:            https://www.pytables.org

BuildRequires:  hdf5-devel >= 1.8
BuildRequires:  bzip2-devel
BuildRequires:  lzo-devel
BuildRequires:  blosc-devel >= 1.5.2
BuildRequires:  python%{python3_pkgversion}-devel
BuildRequires:  python%{python3_pkgversion}-setuptools
%if 0%{?mdkver}
BuildRequires:  glibc-devel
BuildRequires:  python%{python3_pkgversion}-cython >= 0.13
%else
BuildRequires:  python%{python3_pkgversion}-Cython >= 0.13
%endif
BuildRequires:  python%{python3_pkgversion}-numpy
BuildRequires:  python%{python3_pkgversion}-numexpr >= 2.4
BuildRequires:  python%{python3_pkgversion}-six
BuildRequires:  python%{python3_pkgversion}-mock

%global _description %{expand:
PyTables is a package for managing hierarchical datasets and designed
to efficiently and easily cope with extremely large amounts of data.}

%description %_description

%package -n python3-tables
Summary:        %{summary}

Requires:       python%{python3_pkgversion}-numpy
Requires:       python%{python3_pkgversion}-six
Requires:       python%{python3_pkgversion}-numexpr >= 2.4
%{?python_provide:%python_provide python%{python3_pkgversion}-tables}

%description -n python3-tables %_description

%package        doc
Summary:        Documentation for PyTables
BuildArch:      noarch

%description doc
The %{name}-doc package contains the documentation for %{name}.

%prep
%setup -n PyTables-%{version} -q
%patch0 -p1

# https://github.com/PyTables/PyTables/issues/735
%ifarch s390x
%patch1 -p1
%endif

%if "%{?python3_version}" == "3.10"
%patch2 -p1
%endif

%patch3 -p1
%patch4 -p1

cp -a %{SOURCE1} pytablesmanual.pdf

echo "import sys, tables; sys.exit(tables.test(verbose=1))" > bench/check_all.py

# Make sure we are not using anything from the bundled blosc by mistake
find c-blosc -mindepth 1 -maxdepth 1 -name hdf5 -prune -o -exec rm -r {} +

%build
%py3_build

%install
chmod -x examples/check_examples.sh
sed -i 's|bin/env |bin/|' utils/*

%py3_install

%check

# OOM during tests on s390
%ifnarch s390
PYTHONPATH=%{buildroot}%{python3_sitearch} %{__python3} bench/check_all.py
%endif

%files -n python%{python3_pkgversion}-tables
%license LICENSE.txt LICENSES
%{_bindir}/ptdump
%{_bindir}/ptrepack
%{_bindir}/pt2to3
%{_bindir}/pttree
%{python3_sitearch}/tables/
%{python3_sitearch}/tables-%{version}*.egg-info/
%if 0%{?mdkver}
%exclude /usr/lib/debug/
%exclude /usr/src/debug/
%endif

%files doc
%license LICENSE.txt LICENSES
%doc pytablesmanual.pdf
%doc [A-KM-Za-z]*.txt
%doc examples/
%if 0%{?mdkver}
%exclude /usr/lib/debug/
%exclude /usr/src/debug/
%endif

%changelog
* Fri Jun 04 2021 Python Maint <python-maint@redhat.com> - 3.6.1-3
- Rebuilt for Python 3.10

* Wed Jan 27 2021 Fedora Release Engineering <releng@fedoraproject.org> - 3.6.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_34_Mass_Rebuild

* Thu Nov 12 2020 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.6.1-1
- Update to latest version (#1761990)

* Wed Jul 29 2020 Fedora Release Engineering <releng@fedoraproject.org> - 3.5.2-10
- Rebuilt for https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild

* Thu Jun 25 2020 Orion Poplawski <orion@cora.nwra.com> - 3.5.2-9
- Rebuild for hdf5 1.10.6

* Mon May 25 2020 Miro Hrončok <mhroncok@redhat.com> - 3.5.2-8
- Rebuilt for Python 3.9

* Thu Jan 30 2020 Fedora Release Engineering <releng@fedoraproject.org> - 3.5.2-7
- Rebuilt for https://fedoraproject.org/wiki/Fedora_32_Mass_Rebuild

* Thu Oct 03 2019 Miro Hrončok <mhroncok@redhat.com> - 3.5.2-6
- Rebuilt for Python 3.8.0rc1 (#1748018)

* Mon Aug 19 2019 Miro Hrončok <mhroncok@redhat.com> - 3.5.2-5
- Rebuilt for Python 3.8

* Fri Jul 26 2019 Fedora Release Engineering <releng@fedoraproject.org> - 3.5.2-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_31_Mass_Rebuild

* Fri Jul 12 2019 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.5.2-3
- Add patch to fix build on python3.8 (#1718246)

* Fri Jun 28 2019 Miro Hrončok <mhroncok@redhat.com> - 3.5.2-2
- Subpackage python2-tables has been removed
  See https://fedoraproject.org/wiki/Changes/Mass_Python_2_Package_Removal

* Sat Jun  1 2019 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.5.2-1
- Update to latest version (#1715694)

* Wed May 22 2019 Miro Hrončok <mhroncok@redhat.com> - 3.5.1-1
- Update to 3.5.1 (#1687831)
- Fix build under python3.8 (#1712818)

* Sat Mar 16 2019 Orion Poplawski <orion@nwra.com> - 3.4.4-5
- Rebuild for hdf5 1.10.5

* Sun Mar  3 2019 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.4.4-4
- Backport patch from upstream for numpy 1.16 compatibility (#1675793)

* Sat Feb 02 2019 Fedora Release Engineering <releng@fedoraproject.org> - 3.4.4-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_30_Mass_Rebuild

* Sun Nov 18 2018 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.4.4-3
- Drop explicit locale setting
  See https://fedoraproject.org/wiki/Changes/Remove_glibc-langpacks-all_from_buildroot

* Sat Jul 14 2018 Fedora Release Engineering <releng@fedoraproject.org> - 3.4.4-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_29_Mass_Rebuild

* Sun Jun 24 2018 Miro Hrončok <mhroncok@redhat.com> - 3.4.4-1
- Update to 3.4.4 (#1570227)

* Tue Jun 19 2018 Miro Hrončok <mhroncok@redhat.com> - 3.4.2-3
- Rebuilt for Python 3.7

* Wed Feb 28 2018 Iryna Shcherbina <ishcherb@redhat.com> - 3.4.2-2
- Update Python 2 dependency declarations to new packaging standards
  (See https://fedoraproject.org/wiki/FinalizingFedoraSwitchtoPython3)

* Sat Feb 24 2018 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.4.2-1
- Update to latest version (#1441659)

* Fri Feb 09 2018 Fedora Release Engineering <releng@fedoraproject.org> - 3.3.0-7
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Thu Aug 03 2017 Fedora Release Engineering <releng@fedoraproject.org> - 3.3.0-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Binutils_Mass_Rebuild

* Thu Jul 27 2017 Fedora Release Engineering <releng@fedoraproject.org> - 3.3.0-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Sat Feb 11 2017 Fedora Release Engineering <releng@fedoraproject.org> - 3.3.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild

* Mon Dec 19 2016 Miro Hrončok <mhroncok@redhat.com> - 3.3.0-3
- Rebuild for Python 3.6

* Mon Nov 07 2016 Than Ngo <than@redhat.com> - 3.3.0-2
- rebuild against new blosc due to big endien issue on s390x/ppc64

* Thu Sep 15 2016 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.3.0-1
- Update to latest upstream version (#1352621)

* Tue Jul 19 2016 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 3.2.2-6
- https://fedoraproject.org/wiki/Changes/Automatic_Provides_for_Python_RPM_Packages

* Tue May 17 2016 Orion Poplawski <orion@cora.nwra.com> - 3.2.2-5
- Update provides filter
- Ship python2 package
- Use %%python3_pkgversion for EPEL7 compatibility
- Use current python macros

* Thu Feb 04 2016 Fedora Release Engineering <releng@fedoraproject.org> - 3.2.2-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Thu Jan 21 2016 Orion Poplawski <orion@cora.nwra.com> - 3.2.2-3
- Rebuild for hdf5 1.8.16

* Wed Nov 18 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.2.2-2
- Make sure numexpr is new enough

* Sat Nov 14 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.2.2-1
- Update to latest version

* Tue Nov 10 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 3.2.0-4
- Rebuilt for https://fedoraproject.org/wiki/Changes/python3.5

* Thu Jun 18 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 3.2.0-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_23_Mass_Rebuild

* Sun May 17 2015 Orion Poplawski <orion@cora.nwra.com> - 3.2.0-2
- Rebuild for hdf5 1.8.15

* Thu May  7 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.2.0-1
- Update to 3.2.0

* Thu Jan  8 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.1.2-4.git1619180
- Use blosc on all architectures

* Thu Jan  8 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.1.2-3.git1619180
- Update to latest snapshot and use external blosc

* Wed Jan 07 2015 Orion Poplawski <orion@cora.nwra.com> - 3.1.1-2
- Rebuild for hdf5 1.8.14

* Tue Jan 06 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.1.1-1
- Update to 3.1.1 (#1080889)

* Tue Nov 25 2014 Dan Horák <dan[at]danny.cz> - 3.0.0-8
- workaround OOM during Python3 tests on s390

* Sun Aug 17 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 3.0.0-7
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_22_Mass_Rebuild

* Sat Jun 07 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 3.0.0-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Wed May 28 2014 Kalev Lember <kalevlember@gmail.com> - 3.0.0-5
- Rebuilt for https://fedoraproject.org/wiki/Changes/Python_3.4

* Mon Mar 24 2014 Zbigniew Jędrzejewski-Szmek - 3.0.0-4
- Rebuild for latest blosc

* Fri Jan 10 2014 Zbigniew Jędrzejewski-Szmek - 3.0.0-3
- Move python3 requires to the proper package (#1051691)

* Thu Sep 05 2013 Zbigniew Jędrzejewski-Szmek - 3.0.0-2
- Add python3-tables package

* Wed Aug 21 2013 Thibault North <tnorth@fedoraproject.org> - 3.0.0-1
- Update to 3.0.0

* Sun Aug 04 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.4.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_20_Mass_Rebuild

* Thu May 16 2013 Orion Poplawski <orion@cora.nwra.com> - 2.4.0-3
- Rebuild for hdf5 1.8.11

* Thu Feb 14 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.4.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Sun Oct 28 2012 Thibault North <tnorth@fedoraproject.org> - 2.4.0-1
- Update to 2.4.0

* Sat Jul 21 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.3.1-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Sat Jan 14 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.3.1-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_17_Mass_Rebuild

* Mon Nov 14 2011 Thibault North <tnorth@fedoraproject.org> - 2.3.1-3
- Remove lrucache.py which was deprecated and under AFL license

* Thu Nov 10 2011 Thibault North <tnorth@fedoraproject.org> - 2.3.1-2
- Fixes and subpackage for the docs

* Mon Nov 07 2011 Thibault North <tnorth@fedoraproject.org> - 2.3.1-1
- Fixes and update to 2.3.1
