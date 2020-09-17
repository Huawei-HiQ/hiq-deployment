# ==============================================================================

# Upstream's versioning is bizarre
%global tarvers 2015-src-7.2.0

# Enable automatic download
%undefine _disable_source_fetch

# Disable debug package
%define debug_package %nil

# ==============================================================================

Summary: General dimension convex hull programs
Name: qhull
Version: 2015.2
Release: 7%{?dist}
License: Qhull
Source0: http://www.qhull.org/download/qhull-%{tarvers}.tgz

Patch1: qhull-install-docs-into-subdirs.patch

URL: http://www.qhull.org

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:	devtoolset-8
BuildRequires:	devtoolset-8-gcc
BuildRequires:	devtoolset-8-gcc-c++
BuildRequires:	cmake3
%else
# Fedora > 30 && CentOS 8
BuildRequires:	gcc
BuildRequires:	gcc-c++
BuildRequires:	cmake
%endif
BuildRequires: chrpath
Obsoletes:     qhull < %{version}-%{release}

%description
Qhull is a general dimension convex hull program that reads a set
of points from stdin, and outputs the smallest convex set that contains
the points to stdout.  It also generates Delaunay triangulations, Voronoi
diagrams, furthest-site Voronoi diagrams, and halfspace intersections
about a point.

%package -n libqhull
Summary: -n libqhull
Obsoletes:  libqhull < %{version}-%{release}

%description -n libqhull
%{summary}

%package -n libqhull_r
Summary: libqhull_r
Obsoletes:  libqhull_r < %{version}-%{release}

%description -n libqhull_r
%{summary}
Obsoletes:  libqhull_p < %{version}-%{release}

%package -n libqhull_p
Summary: libqhull_p
Obsoletes:  libqhull_p < %{version}-%{release}

%description -n libqhull_p
%{summary}

%package devel
Summary: Development files for qhull
Requires: lib%{name}%{?_isa} = %{version}-%{release}
Requires: lib%{name}_r%{?_isa} = %{version}-%{release}
Requires: lib%{name}_p%{?_isa} = %{version}-%{release}
Obsoletes:  devel < %{version}-%{release}

%description devel
Qhull is a general dimension convex hull program that reads a set
of points from stdin, and outputs the smallest convex set that contains
the points to stdout.  It also generates Delaunay triangulations, Voronoi
diagrams, furthest-site Voronoi diagrams, and halfspace intersections
about a point.

%prep
%setup -q -n %{name}-%{version}
%patch1 -p1

%build

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 20 \
	--slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
	--slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
	--slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
	--family cmake
scl enable devtoolset-8 -- << \EOF
%else
# Fedora > 30 && CentOS > 7
%set_build_flags
%endif

mkdir -p build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make VERBOSE=1 %{?_smp_mflags}
cd ..

%if 0%{?rhel} && 0%{?rhel} < 8
EOF
%endif

%install
cd build
make VERBOSE=1 DESTDIR=$RPM_BUILD_ROOT install
cd ..

mv -v ${RPM_BUILD_ROOT}/usr/lib ${RPM_BUILD_ROOT}%{_libdir}

chrpath --delete ${RPM_BUILD_ROOT}%{_libdir}/lib*.so.*

%files
%license COPYING.txt
%{_bindir}/*
%{_mandir}/man1/*

%files -n libqhull
%{_libdir}/libqhull.so.*

%post -p /sbin/ldconfig -n libqhull
%postun -p /sbin/ldconfig -n libqhull


%files -n libqhull_r
%{_libdir}/libqhull_r.so.*

%post -p /sbin/ldconfig -n libqhull_r
%postun -p /sbin/ldconfig -n libqhull_r


%files -n libqhull_p
%{_libdir}/libqhull_p.so.*

%post -p /sbin/ldconfig -n libqhull_p
%postun -p /sbin/ldconfig -n libqhull_p

%files devel
%{_libdir}/*.so
%{_includedir}/*
%{_libdir}/libqhullcpp.a
%exclude %{_libdir}/libqhullstatic*.a
%exclude %{_datadir}/doc/qhull


%changelog
* Sat Feb 02 2019 Fedora Release Engineering <releng@fedoraproject.org> - 2015.2-7
- Rebuilt for https://fedoraproject.org/wiki/Fedora_30_Mass_Rebuild

* Sat Jul 14 2018 Fedora Release Engineering <releng@fedoraproject.org> - 2015.2-6
- Rebuilt for https://fedoraproject.org/wiki/Fedora_29_Mass_Rebuild

* Fri Feb 09 2018 Fedora Release Engineering <releng@fedoraproject.org> - 2015.2-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Thu Aug 03 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2015.2-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Binutils_Mass_Rebuild

* Thu Jul 27 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2015.2-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Sat Feb 11 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2015.2-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild

* Fri Apr 29 2016 Ralf Corsépius <corsepiu@fedoraproject.org> - 2015.2-1
- Update to 2015.2-7.2.0.
- Split out libqhull, libqhull_p, libqhull_r packages.
- drop pkgconfig.

* Thu Feb 04 2016 Fedora Release Engineering <releng@fedoraproject.org> - 2003.1-28
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Tue Jan 26 2016 Ralf Corsépius <corsepiu@fedoraproject.org> - 2003.1-27
- Remove %%defattr.
- Add %%license.
- Move docs into *-devel.
- Cleanup spec.

* Thu Jun 18 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-26
- Rebuilt for https://fedoraproject.org/wiki/Fedora_23_Mass_Rebuild

* Sun Aug 17 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-25
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_22_Mass_Rebuild

* Sun Jun 08 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-24
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Mon Apr 14 2014 Jaromir Capik <jcapik@redhat.com> - 2003.1-23
- Fixing format-security flaws (#1037293)

* Tue Aug 06 2013 Ralf Corsépius <corsepiu@fedoraproject.org> - 2003.1-22
- Reflect docdir changes (RHBZ #993921).
- Fix bogus %%changelog date.

* Sun Aug 04 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-21
- Rebuilt for https://fedoraproject.org/wiki/Fedora_20_Mass_Rebuild

* Sun Mar 24 2013 Ralf Corsépius <corsepiu@fedoraproject.org> - 2003.1-20
- Update config.sub,guess for aarch64 (RHBZ #926411).

* Thu Feb 14 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-19
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Sat Jul 21 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-18
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Sun Jul 08 2012 Ralf Corsépius <corsepiu@fedoraproject.org> - 2003.1-17
- Modernize spec.
- Add qhull.pc.
- Misc. 64bit fixes.

* Sat Jan 14 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-16
- Rebuilt for https://fedoraproject.org/wiki/Fedora_17_Mass_Rebuild

* Tue Feb 08 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-15
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Tue Feb 02 2010 Ralf Corsépius <corsepiu@fedoraproject.org> - 2003.1-14
- Apply upstream's qh_gethash patch
- Silence %%setup.
- Remove rpath.

* Sun Jul 26 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-13
- Rebuilt for https://fedoraproject.org/wiki/Fedora_12_Mass_Rebuild

* Wed Feb 25 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2003.1-12
- Rebuilt for https://fedoraproject.org/wiki/Fedora_11_Mass_Rebuild

* Thu May 22 2008 Tom "spot" Callaway <tcallawa@redhat.com> - 2003.1-11
- fix license tag

* Tue Mar 04 2008 Ralf Corsépius <rc040203@freenet.de> - 2003.1-10
- Add qhull-2003.1-alias.patch (BZ 432309)
  Thanks to Orion Poplawski (orion@cora.nwra.com).

* Sun Feb 10 2008 Ralf Corsépius <rc040203@freenet.de> - 2003.1-9
- Rebuild for gcc43.

* Wed Aug 22 2007 Ralf Corsépius <rc040203@freenet.de> - 2003.1-8
- Mass rebuild.

* Wed Jun 20 2007 Ralf Corsépius <rc040203@freenet.de> - 2003.1-7
- Remove *.la.

* Tue Sep 05 2006 Ralf Corsépius <rc040203@freenet.de> - 2003.1-6
- Mass rebuild.

* Fri Feb 17 2006 Ralf Corsépius <rc040203@freenet.de> - 2003.1-5
- Disable static libs.
- Fixup some broken links in doc.
- Add %%{?dist}.

* Sun May 22 2005 Jeremy Katz <katzj@redhat.com> - 2003.1-4
- rebuild on all arches

* Wed Apr  6 2005 Michael Schwendt <mschwendt[AT]users.sf.net>
- rebuilt

* Sun Aug 08 2004 Ralf Corsepius <ralf[AT]links2linux.de>	- 2003.1-0.fdr.2
- Use default documentation installation scheme.

* Fri Jul 16 2004 Ralf Corsepius <ralf[AT]links2linux.de>	- 2003.1-0.fdr.1
- Initial Fedora RPM.
