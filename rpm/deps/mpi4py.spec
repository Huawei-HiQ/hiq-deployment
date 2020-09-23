%global with_mpich 1

%global OPENMPI 1
# Run full testsuite or just with 1 core
%global FULLTESTS 0

#global commit 39ca784226460f9e519507269ebb29635dc8bd90
%{?commit:%global shortcommit %(c=%{commit}; echo ${c:0:12})}

%global dill_version 0.3.2

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
%endif

%undefine _disable_source_fetch

# Disable debug package
%define debug_package %nil

# ==============================================================================

Name:           mpi4py
Version:        3.0.3
Release:        6%{?dist}
Summary:        Python bindings of the Message Passing Interface (MPI)

License:        BSD
URL:            https://mpi4py.readthedocs.io/en/stable/
%if %{defined commit}
Source0:        https://bitbucket.org/mpi4py/mpi4py/get/%{commit}.tar.gz#/%{name}-%{shortcommit}.tar.gz
%else
Source0:        https://bitbucket.org/mpi4py/mpi4py/downloads/mpi4py-%{version}.tar.gz
%endif
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
Source1:	https://files.pythonhosted.org/packages/source/d/dill/dill-%{dill_version}.zip
%endif

BuildRequires:  python%{python3_pkgversion}-devel
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:	devtoolset-8-gcc
BuildRequires:	devtoolset-8-gcc-c++
BuildRequires:  python36-setuptools
BuildRequires:  python36-Cython >= 0.22
# For testing
BuildRequires:  python36-numpy
BuildRequires:  python36-simplejson
BuildRequires:  python36-PyYAML
%else
BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  python%{python3_pkgversion}-setuptools
BuildRequires:  python%{python3_pkgversion}-Cython >= 0.22
BuildRequires:  python%{python3_pkgversion}-numpy
BuildRequires:  python%{python3_pkgversion}-simplejson
BuildRequires:  python%{python3_pkgversion}-dill
%if 0%{?is_opensuse}
# OpenSUSE
BuildRequires:  environment-modules
BuildRequires:  python%{python3_pkgversion}-PyYAML
%else
# Fedora > 30 && CentOS > 7
# For testing
BuildRequires:  python%{python3_pkgversion}-yaml
%endif
%endif

%global _description %{expand:
This package is constructed on top of the MPI-1/MPI-2 specification and
provides an object oriented interface which closely follows MPI-2 C++
bindings. It supports point-to-point (sends, receives) and collective
(broadcasts, scatters, gathers) communications of any picklable Python
object as well as optimized communications of Python object exposing the
single-segment buffer interface (NumPy arrays, built-in bytes/string/array
objects).}

%description %_description

%package docs
Summary:        Documentation for %{name}
Requires:       %{name}-common = %{version}-%{release}
BuildArch:      noarch
%description docs
This package contains the documentation and examples for %{name}.

%package -n python%{python3_pkgversion}-mpi4py
Requires:       %{name}-common = %{version}-%{release}
Summary:        Python %{python3_version} bindings of the Message Passing Interface (MPI)
%{?python_provide:%python_provide python%{python3_pkgversion}-mpi4py}
%description -n python%{python3_pkgversion}-mpi4py %_description

%package -n python%{python3_pkgversion}-mpi4py-openmpi
BuildRequires:  openmpi-devel
Requires:       %{name}-common = %{version}-%{release}
%if (0%{?rhel} && 0%{?rhel} < 8) || (0%{?is_opensuse})
# CentOS 7 && OpenSUSE
%else
# Fedora > 30 && CentOS 8
Requires:       python%{python3_pkgversion}-openmpi%{?_isa}
%endif
Summary:        Python %{python3_version} bindings of MPI, Open MPI version
Provides:       python%{python3_pkgversion}-mpi4py-runtime = %{version}-%{release}
%{?python_provide:%python_provide python%{python3_pkgversion}-mpi4py-openmpi}
%description -n python%{python3_pkgversion}-mpi4py-openmpi %_description

This package contains %{name} compiled against Open MPI.


%package common
Summary:        Common files for mpi4py packages
BuildArch:      noarch
Requires:       %{name}-common = %{version}-%{release}
Obsoletes:	common < %{version}-%{release}
%description common
This package contains the license file shared between the subpackages of %{name}.

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
%package -n python3-dill
Summary:	Serialize all of Python
License:	BSD
BuildArch:	noarch
%{?python_provide:%python_provide python3-dill}
%description -n python3-dill
Dill extends python's 'pickle' module for serializing and de-serializing 
python objects to the majority of the built-in python types. 
Dill provides the user the same interface as the 'pickle' module, and also 
includes some additional features. In addition to pickling python objects, dill
provides the ability to save the state of an interpreter session in a single 
command. 
%endif


%prep
%if 0%{?rhel} && 0%{?rhel} < 8
%autosetup -p1 %{?commit:-n %{name}-%{name}-%{shortcommit}} -a1
%else
%autosetup -p1 %{?commit:-n %{name}-%{name}-%{shortcommit}}
%endif
# delete docs/source
# this is just needed to generate docs/*
rm -r docs/source

# work around "wrong-file-end-of-line-encoding"
for file in $(find | grep runtests.bat); do
    sed -i 's/\r//' $file
done

# Save current src/__init__.py for mpich
# cp src/mpi4py/__init__.py .__init__mpich.py
cp src/mpi4py/__init__.py .__init__openmpi.py

# Remove precythonized C sources
rm $(grep -rl '/\* Generated by Cython')


%build

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
pushd dill-%{dill_version}
%py3_build
popd

scl enable devtoolset-8 -- <<\EOF
%else
%if 0%{?is_opensuse}
%global _openmpi_load \
 . /etc/profile.d/modules.sh; \
 module load gnu-openmpi;
%global _openmpi_unload  \
 . /etc/profile.d/modules.sh; \
 module unload gnu-openmpi;
%else
# Fedora > 30 && CentOS > 7
%set_build_flags
%endif
%endif

# Build parallel versions: set compiler variables to MPI wrappers
export CC=mpicc
export CXX=mpicxx

# Build OpenMPI version
%{_openmpi_load}
ompi_info
cp .__init__openmpi.py src/mpi4py/__init__.py
%py3_build
mv build openmpi
%{_openmpi_unload}

%if 0%{?rhel} && 0%{?rhel} < 8
EOF
%endif

%install

%if 0%{?rhel} && 0%{?rhel} < 8
pushd dill-%{dill_version}
%py3_install
popd
%endif

# Install OpenMPI version
%{_openmpi_load}
cp .__init__openmpi.py src/mpi4py/__init__.py
mv openmpi build
%py3_install
mkdir -p %{buildroot}%{python3_sitearch}/openmpi
mv %{buildroot}%{python3_sitearch}/%{name}/ %{buildroot}%{python3_sitearch}/%{name}*.egg-info %{buildroot}%{python3_sitearch}/openmpi
mv build openmpi
%{_openmpi_unload}

%if (0%{?rhel} && 0%{?rhel} < 8) || (0%{?sle_version} && 0%{?sle_version} < 150200)
# CentOS 7 & OpenSUSE/leap 15.1 openmpi package does not define the python3-openmpi package
mkdir -p %{buildroot}/%{python3_sitearch}/openmpi
cat << \EOF > %{buildroot}/%{python3_sitearch}/openmpi.pth
import sys, os; s = '%{python3_sitearch}/openmpi'; s and (s in sys.path or sys.path.append(s))
EOF
%endif

%{?py_byte_compile:%py_byte_compile %{__python3} %{buildroot}%{python3_sitelib}}
%{?py_byte_compile:%py_byte_compile %{__python3} %{buildroot}%{python3_sitearch}}

%check
# test openmpi?
%if 0%{?OPENMPI}
%{_openmpi_load}
cp .__init__openmpi.py src/mpi4py/__init__.py
mv openmpi build
PYTHONPATH=%{buildroot}%{python3_sitearch}/openmpi \
    mpiexec --allow-run-as-root -np 1 python3 test/runtests.py -v --no-builddir \
    -e spawn  \
%ifarch ppc64le
    -e test_datatype
%endif

# test_datatype: https://bitbucket.org/mpi4py/mpi4py/issues/127/test-failure-with-openmpi-on-ppc64le

%if 0%{?FULLTESTS}
# Allow running with more processes than cores
export OMPI_MCA_rmaps_base_oversubscribe=1
PYTHONPATH=%{buildroot}%{python3_sitearch}/openmpi \
    mpiexec -np 5 python3 test/runtests.py -v --no-builddir -e spawn
PYTHONPATH=%{buildroot}%{python3_sitearch}/openmpi \
    mpiexec -np 8 python3 test/runtests.py -v --no-builddir -e spawn
%endif
mv build openmpi
%{_openmpi_unload}
%endif


%files common
%license LICENSE.rst
%doc CHANGES.rst DESCRIPTION.rst README.rst

%files -n python%{python3_pkgversion}-mpi4py-openmpi
%if (0%{?rhel} && 0%{?rhel} < 8) || (0%{?is_opensuse} && 0%{?sle_version} < 150200)
# CentOS 7
%dir %{python3_sitearch}/openmpi
%{python3_sitearch}/openmpi.pth
%endif
%{python3_sitearch}/openmpi/%{name}-*.egg-info
%{python3_sitearch}/openmpi/%{name}

%files docs
%doc docs/* demo

	
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
%files -n python3-dill
%exclude %{_bindir}/*
%{python3_sitelib}/*
%endif

%changelog
* Sat Aug 01 2020 Fedora Release Engineering <releng@fedoraproject.org> - 3.0.3-6
- Second attempt - Rebuilt for
  https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild

* Tue Jul 28 2020 Fedora Release Engineering <releng@fedoraproject.org> - 3.0.3-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild

* Tue Jun 23 2020 Gwyn Ciesla <gwync@protonmail.com> - 3.0.3-4
- BR python3-setuptools

* Tue May 26 2020 Miro Hrončok <mhroncok@redhat.com> - 3.0.3-3
- Rebuilt for Python 3.9

* Sun Mar  1 2020 Thomas Spura <tomspur@fedoraproject.org> - 3.0.3-2
- Fix syntax of check section (#1791973)

* Sun Feb 23 2020 Orion Poplawski <orion@nwra.com> - 3.0.3-1
- Update to 3.0.3

* Wed Jan 29 2020 Fedora Release Engineering <releng@fedoraproject.org> - 3.0.2-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_32_Mass_Rebuild

* Thu Oct 10 2019 Orion Poplwski <orion@nwra.com> - 3.0.2-5
- Re-enable mpi thread multiple since openmpi is built with it
- Re-enable openmpi tests on arm, mpich is still failing

* Thu Oct 03 2019 Miro Hrončok <mhroncok@redhat.com> - 3.0.2-4
- Rebuilt for Python 3.8.0rc1 (#1748018)

* Mon Aug 19 2019 Miro Hrončok <mhroncok@redhat.com> - 3.0.2-3
- Rebuilt for Python 3.8

* Thu Jul 25 2019 Fedora Release Engineering <releng@fedoraproject.org> - 3.0.2-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_31_Mass_Rebuild

* Tue Jun 11 2019 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.0.2-1
- Update to latest version (#1719298)

* Sun Mar 17 2019 Miro Hrončok <mhroncok@redhat.com> - 3.0.1-2
- Subpackages python2-mpi4py, python2-mpi4py-openmpi have been removed
  See https://fedoraproject.org/wiki/Changes/Mass_Python_2_Package_Removal

* Sat Feb 16 2019 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 3.0.1-1
- Update to latest bugfix version (#1677683)

* Wed Feb 13 2019 Orion Poplawski <orion@nwra.com> - 3.0.0-6
- Rebuild for openmpi 3.1.3

* Fri Feb 01 2019 Fedora Release Engineering <releng@fedoraproject.org> - 3.0.0-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_30_Mass_Rebuild

* Fri Jul 13 2018 Fedora Release Engineering <releng@fedoraproject.org> - 3.0.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_29_Mass_Rebuild

* Tue Jun 19 2018 Miro Hrončok <mhroncok@redhat.com> - 3.0.0-3
- Rebuilt for Python 3.7

* Thu Feb 08 2018 Fedora Release Engineering <releng@fedoraproject.org> - 3.0.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Sat Nov 11 2017 Thomas Spura <tomspur@fedoraproject.org> - 3.0.0-1
- update to 3.0.0 (#1510901)

* Sun Oct 29 2017 Thomas Spura <tomspur@fedoraproject.org> - 2.0.0-14
- Set threads to serialized in openmpi due to #1105902

* Sun Oct 29 2017 Thomas Spura <tomspur@fedoraproject.org> - 2.0.0-13
- disable tests on openmpi due to #1105902 (#1423965)

* Thu Aug 03 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2.0.0-12
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Binutils_Mass_Rebuild

* Wed Jul 26 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2.0.0-11
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Thu Jun 15 2017 Thomas Spura <tomspur@fedoraproject.org> - 2.0.0-10
- Reenable python3 package (#1461023)

* Fri Feb 10 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2.0.0-9
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild

* Wed Nov 2 2016 Orion Poplawski <orion@cora.nwra.com> - 2.0.0-8
- Require appropriate mpi python support packages
- Remove useless provides

* Mon Oct 24 2016 Orion Poplawski <orion@cora.nwra.com> - 2.0.0-7
- Use upstream tox commands for tests
- Minor spec cleanup

* Mon Oct 24 2016 Orion Poplawski <orion@cora.nwra.com> - 2.0.0-7
- Enable python3 for EPEL

* Fri Oct 21 2016 Orion Poplawski <orion@cora.nwra.com> - 2.0.0-6
- Rebuild for openmpi 2.0

* Tue Jul 19 2016 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.0.0-5
- https://fedoraproject.org/wiki/Changes/Automatic_Provides_for_Python_RPM_Packages

* Thu Feb 04 2016 Fedora Release Engineering <releng@fedoraproject.org> - 2.0.0-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Thu Nov 12 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.0.0-3
- Rebuilt for https://fedoraproject.org/wiki/Changes/python3.5

* Mon Nov 9 2015 Orion Poplawski <orion@cora.nwra.com> - 2.0.0-2
- Bump obsoletes

* Sat Oct 24 2015 Thomas Spura <tomspur@fedoraproject.org> - 2.0.0-1
- update to 2.0.0

* Wed Oct 14 2015 Thomas Spura <tomspur@fedoraproject.org> - 1.3.1-16
- Rename mpi4py packages to python2-mpi4py

* Tue Sep 15 2015 Orion Poplawski <orion@cora.nwra.com> - 1.3.1-15
- Rebuild for openmpi 1.10.0

* Tue Aug 18 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 1.3.1-14
- Rebuild for rpm-mpi-hooks-3-2

* Mon Aug 17 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 1.3.1-13
- Rebuild for rpm-mpi-hooks-3-1

* Sat Aug 15 2015 Zbigniew Jędrzejewski-Szmek <zbyszek@in.waw.pl> - 1.3.1-12
- Remove requires filtering... not necessary anymore

* Mon Aug 10 2015 Sandro Mani <manisandro@gmail.com> - 1.3.1-11
- Rebuild for RPM MPI Requires Provides Change

* Wed Jul 29 2015 Karsten Hopp <karsten@redhat.com> 1.3.1-10
- mpich is available on ppc64 now

* Mon Jun 29 2015 Thomas Spura <tomspur@fedoraproject.org> - 1.3.1-9
- Use new py_build/install macros

* Wed Jun 17 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.3.1-8
- Rebuilt for https://fedoraproject.org/wiki/Fedora_23_Mass_Rebuild

* Sat Mar 14 2015 Thomas Spura <tomspur@fedoraproject.org> - 1.3.1-7
- remove %%py3dir
- use python2 macros instead of unversioned ones

* Thu Mar 12 2015 Thomas Spura <tomspur@fedoraproject.org> - 1.3.1-6
- Rebuild for changed mpich libraries

* Sun Aug 17 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.3.1-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_22_Mass_Rebuild

* Sat Jun 07 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.3.1-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Fri May 9 2014 Orion Poplawski <orion@cora.nwra.com> - 1.3.1-3
- Rebuild for Python 3.4

* Mon Feb 24 2014 Thomas Spura <tomspur@fedoraproject.org> - 1.3.1-2
- Rebuilt for new mpich-3.1

* Thu Aug  8 2013 Thomas Spura <tomspur@fedoraproject.org> - 1.3.1-1
- update to 1.3.1

* Sat Aug 03 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.3-9
- Rebuilt for https://fedoraproject.org/wiki/Fedora_20_Mass_Rebuild

* Sat Jul 20 2013 Deji Akingunola <dakingun@gmail.com> - 1.3-8
- Rename mpich2 sub-packages to mpich and rebuild for mpich-3.0

* Thu Feb 14 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.3-7
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Wed Nov 14 2012 Thomas Spura <tomspur@fedoraproject.org> - 1.3-6
- rebuild for newer mpich2

* Sat Aug  4 2012 Thomas Spura <tomspur@fedoraproject.org> - 1.3-5
- conditionalize mpich2 support, there is no mpich2 on el6-ppc64

* Fri Aug 03 2012 David Malcolm <dmalcolm@redhat.com> - 1.3-4
- rebuild for https://fedoraproject.org/wiki/Features/Python_3.3

* Fri Jul 20 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.3-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Wed Jan 25 2012 Thomas Spura <tomspur@fedoraproject.org> - 1.3-2
- filter requires in pysitearch/openmpi/mpi4py/lib-pmpi/lib (#741104)

* Fri Jan 20 2012 Thomas Spura <tomspur@fedoraproject.org> - 1.3-1
- update to 1.3
- filter provides in pythonsitearch
- run tests differently

* Fri Jan 13 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.2.2-7
- Rebuilt for https://fedoraproject.org/wiki/Fedora_17_Mass_Rebuild

* Wed Mar 30 2011 Deji Akingunola <dakingun@gmail.com> - 1.2.2-6
- Rebuild for mpich2 soname bump

* Tue Feb 08 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.2.2-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Wed Dec 29 2010  David Malcolm <dmalcolm@redhat.com> - 1.2.2-4
- rebuild for newer python3

* Tue Oct 19 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2.2-3
- rebuild for new mpich2 and openmpi versions

* Wed Sep 29 2010 jkeating - 1.2.2-2
- Rebuilt for gcc bug 634757

* Wed Sep 15 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2.2-1
- update to new version

* Sun Aug 22 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2.1-6
- rebuild with python3.2
  http://lists.fedoraproject.org/pipermail/devel/2010-August/141368.html

* Wed Jul 21 2010 David Malcolm <dmalcolm@redhat.com> - 1.2.1-5
- Rebuilt for https://fedoraproject.org/wiki/Features/Python_2.7/MassRebuild

* Wed Jul  7 2010 Thomas Spura <tomspur@fedoreproject.org> - 1.2.1-4
- doc package needs to require common package, because of licensing

* Sun Apr 11 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2.1-3
- also provides python2-mpi4py-*

* Sat Feb 27 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2.1-2
- delete R on the main package in docs subpackage
  (main package is empty -> would be an unresolved dependency)

* Sat Feb 27 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2.1-1
- new version
- removing of hidden file not needed anymore (done upstream)
- fix spelling error builtin -> built-in

* Fri Feb 26 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2-7
- introduce OPENMPI and MPD macros to easy enable/disable the testsuite

* Tue Feb 16 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2-6
- don't delete *.pyx/*.pyd
- delete docs/source

* Mon Feb  8 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2-5
- disable testsuite

* Sun Feb  7 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2-4
- enable testsuite
- move huge docs into docs subpackage

* Sun Feb  7 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2-3
- delete lam building
- install to correct locations

* Sun Feb  7 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2-2
- compile for different mpi versions

* Sun Feb  7 2010 Thomas Spura <tomspur@fedoraproject.org> - 1.2-1
- initial import
