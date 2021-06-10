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

# ==============================================================================

Summary:        Fast numerical array expression evaluator for Python and NumPy
Name:           python-numexpr
Version:        2.7.1
Release:        6%{?dist}
URL:            https://github.com/pydata/numexpr
Source0:        https://github.com/pydata/numexpr/archive/v%{version}/numexpr-%{version}.tar.gz
License:        MIT

%if 0%{?mdkver}
BuildRequires:  clang
BuildRequires:  glibc-devel
%else
BuildRequires:  gcc-c++
%endif
BuildRequires:  python%{python3_pkgversion}-devel
BuildRequires:  python%{python3_pkgversion}-numpy
BuildRequires:  python%{python3_pkgversion}-setuptools

%global _description %{expand:
The numexpr package evaluates multiple-operator array expressions many
times faster than NumPy can. It accepts the expression as a string,
analyzes it, rewrites it more efficiently, and compiles it to faster
Python code on the fly. It’s the next best thing to writing the
expression in C and compiling it with a specialized just-in-time (JIT)
compiler, i.e. it does not require a compiler at runtime.}

%description %_description

%package -n python3-numexpr
Summary:        %{summary}
Requires:       python%{python3_pkgversion}-numpy >= 1.6
%{?python_provide:%python_provide python%{python3_pkgversion}-numexpr}

%description -n python3-numexpr %_description

This is the version for Python 3.

%prep
%autosetup -n numexpr-%{version} -p1

%build
%py3_build

%install
%py3_install
chmod 0755 %{buildroot}%{python3_sitearch}/numexpr/cpuinfo.py
sed -i "1s|/usr/bin/env python$|%{__python3}|" %{buildroot}%{python3_sitearch}/numexpr/cpuinfo.py

%check
pushd build/lib.linux*%{python3_version}
PYTHONPATH=%{buildroot}%{python3_sitearch} %{__python3} -c 'import numexpr, sys; sys.exit(not numexpr.test().wasSuccessful())'
popd

%files -n python%{python3_pkgversion}-numexpr
%license LICENSE.txt
%doc ANNOUNCE.rst RELEASE_NOTES.rst README.rst
%{python3_sitearch}/numexpr/
%{python3_sitearch}/numexpr-%{version}-py*.egg-info
%if 0%{?mdkver}
%exclude /usr/lib/debug/
%exclude /usr/src/debug/
%endif

%changelog
* Fri Jun 04 2021 Python Maint <python-maint@redhat.com> - 2.7.1-6
- Rebuilt for Python 3.10

* Wed Jan 27 2021 Fedora Release Engineering <releng@fedoraproject.org> - 2.7.1-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_34_Mass_Rebuild

* Wed Jul 29 2020 Fedora Release Engineering <releng@fedoraproject.org> - 2.7.1-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild

* Mon May 25 2020 Miro Hrončok <mhroncok@redhat.com> - 2.7.1-3
- Rebuilt for Python 3.9

* Thu Jan 30 2020 Fedora Release Engineering <releng@fedoraproject.org> - 2.7.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_32_Mass_Rebuild

* Sun Jan  5 2020 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.7.1-1
- Update to latest version (#1787863)

* Thu Oct 03 2019 Miro Hrončok <mhroncok@redhat.com> - 2.7.0-3
- Rebuilt for Python 3.8.0rc1 (#1748018)

* Sun Aug 18 2019 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.7.0-2
- Rebuilt for Python 3.8

* Sat Aug 17 2019 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.7.0-1
- Update to latest version (#1614993)
- Various modernization to the spec file. Actually fail %%check if the test
  suite fails.

* Fri Jul 26 2019 Fedora Release Engineering <releng@fedoraproject.org> - 2.6.6-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_31_Mass_Rebuild

* Mon Jul 08 2019 Miro Hrončok <mhroncok@redhat.com> - 2.6.6-3
- Subpackage python2-numexpr has been removed
  See https://fedoraproject.org/wiki/Changes/Mass_Python_2_Package_Removal

* Sat Feb 02 2019 Fedora Release Engineering <releng@fedoraproject.org> - 2.6.6-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_30_Mass_Rebuild

* Thu Jul 19 2018 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.6.6-1
- Update to latest version (#1491485)
- Update spec file, use versioned python macros

* Sat Jul 14 2018 Fedora Release Engineering <releng@fedoraproject.org> - 2.6.1-11
- Rebuilt for https://fedoraproject.org/wiki/Fedora_29_Mass_Rebuild

* Tue Jun 19 2018 Miro Hrončok <mhroncok@redhat.com> - 2.6.1-10
- Rebuilt for Python 3.7

* Fri Feb 09 2018 Fedora Release Engineering <releng@fedoraproject.org> - 2.6.1-9
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Tue Oct 24 2017 Haïkel Guémar <hguemar@fedoraproject.org> - 2.6.1-8
- Fix ELF stripping

* Thu Aug 03 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2.6.1-7
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Binutils_Mass_Rebuild

* Thu Jul 27 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2.6.1-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Sat Feb 11 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2.6.1-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild

* Tue Dec 13 2016 Stratakis Charalampos <cstratak@redhat.com> - 2.6.1-4
- Rebuild for Python 3.6

* Sat Jul 30 2016 Petr Viktorin <pviktori@redhat.com> - 2.6.1-3
- Make shebang of cpuinfo.py refer to specific Python version (#1361799)

* Tue Jul 19 2016 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.6.1-2
- https://fedoraproject.org/wiki/Changes/Automatic_Provides_for_Python_RPM_Packages

* Tue Jul 19 2016 Thibault North <tnorth@fedoraproject.org> - 2.6.1-1
- Update to 2.6.1
- Fix project URL
- Fix cpuinfo permission in py3 package

* Wed Jun  1 2016 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.6.0-1
- Update to latest version

* Tue May 17 2016 Orion Poplawski <orion@cora.nwra.com> - 2.5.2-2
- Update provides filter
- Use %%python3_pkgversion for EPEL7 compatibility

* Tue Apr 12 2016 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.5.2-1
- Update to latest version (#1305251)

* Sat Feb  6 2016 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.5-1
- Update to latest version

* Thu Feb 04 2016 Fedora Release Engineering <releng@fedoraproject.org> - 2.4.6-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Wed Nov 18 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.4.6-2
- Create python2 subpackage

* Sat Nov 14 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.4.6-1
- Update to latest version

* Tue Nov 10 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.3-7
- Rebuilt for https://fedoraproject.org/wiki/Changes/python3.5

* Thu Jun 18 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.3-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_23_Mass_Rebuild

* Sat May 02 2015 Kalev Lember <kalevlember@gmail.com> - 2.3-5
- Rebuilt for GCC 5 C++11 ABI change

* Sun Aug 17 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.3-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_22_Mass_Rebuild

* Sat Jun 07 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.3-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Wed May 28 2014 Kalev Lember <kalevlember@gmail.com> - 2.3-2
- Rebuilt for https://fedoraproject.org/wiki/Changes/Python_3.4

* Tue Jan 28 2014 Thibault North <tnorth@fedoraproject.org> -2.3-1
- Update to new release 2.3

* Fri Jan 17 2014 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.2.2-2
- Move requirements to the proper package (#1054683)

* Sun Sep 29 2013 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.2.2-1
- Update to 2.2.2 (#1013130)

* Mon Sep 09 2013 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.2.1-1
- Update to 2.2.1

* Thu Sep 05 2013 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 2.2-1
- Update to 2.2
- Add python3-numexpr package

* Sun Aug 04 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.0.1-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_20_Mass_Rebuild

* Thu Feb 14 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.0.1-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Sat Jul 21 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.0.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Sun Jan 8 2012  Thibault North <tnorth@fedoraproject.org> - 2.0.1-1
- Update to 2.0.1

* Sun Nov 27 2011 Thibault North <tnorth@fedoraproject.org> - 2.0-1
- Update to 2.0

* Sun Oct 30 2011 Thibault North <tnorth@fedoraproject.org> - 1.4.2-2
- Add check section
- Fix permissions and remove useless sections

* Thu Oct 20 2011 Thibault North <tnorth@fedoraproject.org> - 1.4.2-1
- Updated to 1.4.2

* Fri Apr 29 2011 Thibault North <tnorth@fedoraproject.org> - 1.4.1-3
- Fix buildroot issue

* Tue Dec 21 2010 Thibault North <tnorth@fedoraproject.org> - 1.4.1-2
- Fixes for the review process

* Fri Nov 05 2010 Thibault North <tnorth@fedoraproject.org> - 1.4.1-1
- Initial package based on Mandriva's one
