%global srcname sympy

%global sympy_version 1.6.2
%global mpmath_version 1.1.0

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

Name:           python-%{srcname}
Version:        %{sympy_version}
Release:        1%{?dist}
Summary:        A Python library for symbolic mathematics
License:        BSD
URL:            http://sympy.org/
Source0: %{pypi_source}
Source1: %{pypi_source mpmath %{mpmath_version}}
# Default to python3 in the Cython backend
Patch0:         %{srcname}-python3.patch

BuildArch:      noarch

BuildRequires:  python3-devel

%global _description\
SymPy aims to become a full-featured computer algebra system (CAS)\
while keeping the code as simple as possible in order to be\
comprehensible and easily extensible. SymPy is written entirely in\
Python and does not require any external libraries.

%description %_description

%package -n python3-%{srcname}
Summary:        A Python3 library for symbolic mathematics
Provides:	python3-%{srcname} = %{version}-%{release}
%{?python_provide:%python_provide python3-%{srcname}}

Requires:	python3-mpmath

%description -n python3-%{srcname}
SymPy aims to become a full-featured computer algebra system (CAS)
while keeping the code as simple as possible in order to be
comprehensible and easily extensible. SymPy is written entirely in
Python and does not require any external libraries.

%package -n python3-%{srcname}-examples
Summary:        Sympy examples
%{?python_provide:%python_provide python3-%{srcname}-examples}
Requires:       python3-%{srcname} = %{version}-%{release}

%description -n python3-%{srcname}-examples
This package contains example input for sympy.

%package -n python3-mpmath
Summary:        A Python3 library for symbolic mathematics
%{?python_provide:%python_provide python3-mpmath}

%description -n python3-mpmath
A Python library for symbolic mathematics.

%prep
%autosetup -p1 -n %{srcname}-%{version} -a1

# Do not depend on env
for fil in $(grep -rl "^#\![[:blank:]]*%{_bindir}/env" .); do
  sed -i.orig 's,^\(#\![[:blank:]]*%{_bindir}/\)env python,\1python3,' $fil
  touch -r $fil.orig $fil
  rm -f $fil.orig
done

%build
%py3_build
cd mpmath-%{mpmath_version}
%py3_build

%install
%py3_install
pushd mpmath-%{mpmath_version}
%py3_install
popd

%py_byte_compile %{__python3} %{buildroot}%{python3_sitelib}

## Remove extra files
rm -f %{buildroot}%{_bindir}/{,doc}test

# Don't let an executable script go into the documentation
chmod -R a-x+X examples

# Try to get rid of pyc files, which aren't useful for documentation
find examples/ -name '*.py[co]' -print -delete

%files -n python3-%{srcname}
%doc AUTHORS README.md
%license LICENSE
%{python3_sitelib}/isympy.*
%{python3_sitelib}/__pycache__/isympy.*
%{python3_sitelib}/sympy/
%{python3_sitelib}/sympy-%{version}-py%{python3_version}.egg-info
%{_bindir}/isympy
%{_mandir}/man1/isympy.1*

%files -n python3-%{srcname}-examples
%doc examples/*

%files -n python3-mpmath
%{python3_sitelib}/mpmath
%{python3_sitelib}/mpmath-%{mpmath_version}-py%{python3_version}.egg-info

%changelog
* Mon Aug 10 2020 Jerry James <loganjerry@gmail.com> - 1.6.2-1
- Version 1.6.2

* Wed Jul 29 2020 Fedora Release Engineering <releng@fedoraproject.org> - 1.6.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild

* Thu Jul  2 2020 Jerry James <loganjerry@gmail.com> - 1.6.1-1
- Version 1.6.1
- Drop upstreamed -ast patch

* Wed Jun 24 2020 Jerry James <loganjerry@gmail.com> - 1.6-2
- Add setuptools BR
- Add -ast patch to fix compilation with python 3.9

* Fri May 29 2020 Jerry James <loganjerry@gmail.com> - 1.6-1
- Version 1.6
- Drop upstreamed -doc and -sample-set patches
- Disable testing on 32-bit systems; too many tests need 64-bit integers

* Tue May 26 2020 Miro Hrončok <mhroncok@redhat.com> - 1.5.1-4
- Rebuilt for Python 3.9

* Mon May 11 2020 Jerry James <loganjerry@gmail.com> - 1.5.1-3
- Add -sample-set patch to fix test failure with python 3.9

* Fri Jan 31 2020 Fedora Release Engineering <releng@fedoraproject.org> - 1.5.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_32_Mass_Rebuild

* Wed Jan  8 2020 Jerry James <loganjerry@gmail.com> - 1.5.1-1
- Update to 1.5.1
- Drop upstreamed patches
- Drop upstreamed workaround for numpy with a release candidate version

* Mon Nov  4 2019 Jerry James <loganjerry@gmail.com> - 1.4-6
- Fix broken dependencies in the -texmacs subpackage
- Recommend numexpr

* Fri Sep 13 2019 Jerry James <loganjerry@gmail.com> - 1.4-5
- Add one more patch to fix a python 3.8 warning

* Sat Aug 24 2019 Robert-André Mauchin <zebob.m@gmail.com>  - 1.4-4
- Add patches to fix build with Python 3.8 and Numpy 1.17

* Mon Aug 19 2019 Miro Hrončok <mhroncok@redhat.com> - 1.4-3
- Rebuilt for Python 3.8

* Sat Jul 27 2019 Fedora Release Engineering <releng@fedoraproject.org> - 1.4-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_31_Mass_Rebuild

* Wed Apr 17 2019 Jerry James <loganjerry@gmail.com> - 1.4-1
- Update to 1.4
- Drop -factorial patch

* Sun Feb 03 2019 Fedora Release Engineering <releng@fedoraproject.org> - 1.3-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_30_Mass_Rebuild

* Wed Jan 30 2019 Jerry James <loganjerry@gmail.com> - 1.3-2
- Add -sympify and -factorial patches to work around test failures

* Mon Jan 14 2019 Jerry James <loganjerry@gmail.com> - 1.3-2
- Drop Requires from the -doc subpackage (bz 1665767)

* Sat Oct  6 2018 Jerry James <loganjerry@gmail.com> - 1.3-1
- Update to 1.3
- Drop upstreamed patches: subexpr-lambdify, test-code-quality, tex-encoding
- Drop the python2 subpackage
- Add -python3 patch to ask cython to generate python 3 code

* Tue Aug 14 2018 Miro Hrončok <mhroncok@redhat.com> - 1.2-2
- Fix _subexpr method in lambdify

* Sat Jul 21 2018 Jerry James <loganjerry@gmail.com> - 1.2-1
- Update to 1.2 (bz 1599502)
- Drop upstreamed -python3 patch
- Add -test-code-quality and -doc patches

* Sat Jul 14 2018 Fedora Release Engineering <releng@fedoraproject.org> - 1.1.1-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_29_Mass_Rebuild

* Tue Jun 19 2018 Miro Hrončok <mhroncok@redhat.com> - 1.1.1-5
- Rebuilt for Python 3.7

* Wed Feb 21 2018 Iryna Shcherbina <ishcherb@redhat.com> - 1.1.1-4
- Update Python 2 dependency declarations to new packaging standards
  (See https://fedoraproject.org/wiki/FinalizingFedoraSwitchtoPython3)

* Fri Feb 09 2018 Fedora Release Engineering <releng@fedoraproject.org> - 1.1.1-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Sat Aug 19 2017 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 1.1.1-2
- Python 2 binary package renamed to python2-sympy
  See https://fedoraproject.org/wiki/FinalizingFedoraSwitchtoPython3

* Thu Jul 27 2017 Jerry James <loganjerry@gmail.com> - 1.1.1-1
- Update to 1.1.1 (bz 1468405)

* Thu Jul 27 2017 Fedora Release Engineering <releng@fedoraproject.org> - 1.1-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Mon Jul 24 2017 Jerry James <loganjerry@gmail.com> - 1.1-3
- Fix dependency on python2 from python3 package (bz 1471886)

* Sat Jul  8 2017 Jerry James <loganjerry@gmail.com> - 1.1-2
- Disable tests that fail due to overflow on some 32-bit architectures

* Fri Jul  7 2017 Jerry James <loganjerry@gmail.com> - 1.1-1
- Update to 1.1 (bz 1468405)
- All patches have been upstreamed; drop them all

* Sat Apr  1 2017 Jerry James <loganjerry@gmail.com> - 1.0-7
- Update theano test for theano 0.9

* Sat Feb 11 2017 Fedora Release Engineering <releng@fedoraproject.org> - 1.0-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild

* Fri Jan 20 2017 Iryna Shcherbina <ishcherb@redhat.com> - 1.0-5
- Make documentation scripts non-executable to avoid
  autogenerating Python 2 dependency in sympy-examples (#1360766)

* Fri Jan 13 2017 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 1.0-4
- Run tests in parallel
- Work around some broken tests
- Use python3 in texmacs-sympy (#1360766)

* Thu Dec 22 2016 Miro Hrončok <mhroncok@redhat.com> - 1.0-4
- Rebuild for Python 3.6

* Fri Jul 22 2016 Jerry James <loganjerry@gmail.com> - 1.0-3
- Update the -test patch for the latest matplotlib release

* Tue Jul 19 2016 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.0-3
- https://fedoraproject.org/wiki/Changes/Automatic_Provides_for_Python_RPM_Packages

* Sat Apr  2 2016 Jerry James <loganjerry@gmail.com> - 1.0-2
- Fix bad /usr/bin/env substitution

* Thu Mar 31 2016 Jerry James <loganjerry@gmail.com> - 1.0-1
- Update to 1.0
- All patches have been upstreamed; drop them all
- Add -test patch to fix test failures with recent mpmath
- Recommend scipy

* Fri Feb 05 2016 Fedora Release Engineering <releng@fedoraproject.org> - 0.7.6.1-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Tue Nov 10 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org>
- Rebuilt for https://fedoraproject.org/wiki/Changes/python3.5

* Thu Sep  3 2015 Jerry James <loganjerry@gmail.com> - 0.7.6.1-1
- Update to 0.7.6.1 (bz 1259971)

* Mon Jul  6 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 0.7.6-3
- Fix failure in tests (#1240097)

* Fri Jun 19 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.7.6-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_23_Mass_Rebuild

* Fri Dec  5 2014 Jerry James <loganjerry@gmail.com> - 0.7.6-1
- Update to 0.7.6
- Drop upstreamed -test and -is-tangent patches
- Drop obsolete bug workarounds
- Add python(3)-fastcache BR and R
- Recommend python-theano
- Fix executable bits on tm_sympy

* Tue Sep 16 2014 Jerry James <loganjerry@gmail.com> - 0.7.5-4
- Drop python3-six BR and R now that bz 1140413 is fixed
- Use gmpy2

* Wed Sep  3 2014 Jerry James <loganjerry@gmail.com> - 0.7.5-3
- Install both isympy and python3-isympy to comply with packaging standards
- Add -is-tangent patch (bz 1135677)
- Temporarily disable tests that fail due to mpmath bugs (bz 1127796)
- Fix license handling
- Add python3-six BR and R; see bz 1140413 for details

* Sun Jun 08 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.7.5-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Mon May 19 2014 Bohuslav Kabrda <bkabrda@redhat.com> - 0.7.5-2
- Rebuilt for https://fedoraproject.org/wiki/Changes/Python_3.4

* Thu Mar 13 2014 Jerry James <loganjerry@gmail.com> - 0.7.5-1
- Update to 0.7.5 (bz 1066951)
- Binaries now default to using python3
- Use py3dir macro to simplify python3 build
- Add BRs for more comprehensive testing
- Workaround bz 1075826
- Add -test patch to fix Unicode problem in the tests

* Mon Dec  9 2013 Jerry James <loganjerry@gmail.com> - 0.7.4-1
- Update to 0.7.4
- Python 2 and 3 sources are now in the same tarball

* Fri Oct 18 2013 Jerry James <loganjerry@gmail.com> - 0.7.3-2
- Build a python3 subpackage (bz 982759)

* Fri Aug  2 2013 Jerry James <loganjerry@gmail.com> - 0.7.3-1
- Update to 0.7.3
- Upstream dropped all tutorial translations
- Add graphviz BR for documentation
- Sources now distributed from github instead of googlecode
- Adapt to versionless _docdir in Rawhide

* Mon Jun 17 2013 Jerry James <loganjerry@gmail.com> - 0.7.2-1
- Update to 0.7.2 (bz 866044)
- Add python-pyglet R (bz 890312)
- Package the TeXmacs integration
- Build and provide documentation
- Provide examples
- Minor spec file cleanups

* Fri Feb 15 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.7.1-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Sat Jul 21 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.7.1-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Sat Jan 14 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.7.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_17_Mass_Rebuild

* Tue Oct 11 2011 Jussi Lehtola <jussilehtola@fedoraproject.org> - 0.7.1-1
- Update to 0.7.1.

* Wed Feb 09 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.6.7-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Mon Aug 30 2010 Jussi Lehtola <jussilehtola@fedoraproject.org> - 0.6.7-5
- Patch around BZ #564504.

* Sat Jul 31 2010 David Malcolm <dmalcolm@redhat.com> - 0.6.7-4
- fix a python 2.7 incompatibility

* Thu Jul 22 2010 David Malcolm <dmalcolm@redhat.com> - 0.6.7-3
- Rebuilt for https://fedoraproject.org/wiki/Features/Python_2.7/MassRebuild

* Tue Apr 27 2010 Jussi Lehtola <jussilehtola@fedoraproject.org> - 0.6.7-2
- Added %%check phase.

* Tue Apr 27 2010 Jussi Lehtola <jussilehtola@fedoraproject.org> - 0.6.7-1
- Update to 0.6.7.

* Mon Feb 15 2010 Conrad Meyer <konrad@tylerc.org> - 0.6.6-3
- Patch around private copy nicely; avoid breakage from trying to replace
  a directory with a symlink.

* Mon Feb 15 2010 Conrad Meyer <konrad@tylerc.org> - 0.6.6-2
- Remove private copy of system lib 'mpmath' (rhbz #551576).

* Sun Dec 27 2009 Jussi Lehtola <jussilehtola@fedoraproject.org> - 0.6.6-1
- Update to 0.6.6.

* Sat Nov 07 2009 Jussi Lehtola <jussilehtola@fedoraproject.org> - 0.6.5-1
- Update to 0.6.5.

* Sun Jul 26 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.6.3-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_12_Mass_Rebuild

* Wed Feb 25 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.6.3-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_11_Mass_Rebuild

* Thu Dec 4 2008 Conrad Meyer <konrad@tylerc.org> - 0.6.3-1
- Bump to 0.6.3, supports python 2.6.

* Sat Nov 29 2008 Ignacio Vazquez-Abrams <ivazqueznet+rpm@gmail.com> - 0.6.2-3
- Rebuild for Python 2.6

* Mon Oct 13 2008 Conrad Meyer <konrad@tylerc.org> - 0.6.2-2
- Patch to remove extraneous shebangs.

* Sun Oct 12 2008 Conrad Meyer <konrad@tylerc.org> - 0.6.2-1
- Initial package.
