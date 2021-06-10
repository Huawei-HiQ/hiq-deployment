%global srcname pyscf
%global pyscf_version 1.7.4
%global libcint_version 3.1.1

%if 0%{?fedora} >= 33
%global blaslib flexiblas
%global blasvar %{nil}
%else
%if 0%{?mdkver}
%global blaslib blas
%global blasvar %{nil}
%else
%global blaslib openblas
%if 0%{?is_opensuse}
%global blasvar _openmp
%else
%global blasvar o
%endif
%endif
%endif

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

# Omit internal libraries from dependency generation. We can omit all
# the provides
%global __provides_exclude_from ^%{python3_sitearch}/pyscf/lib/.*\\.so$

%global __requires_exclude ^(libcint\\.so|libxc\\.so|libao2mo\\.so|libcgto\\.so|libcvhf\\.so|libfci\\.so|libnp_helper\\.so).*$

# ==============================================================================

Name:           python-%{srcname}
Version:        %{pyscf_version}
Release:        1%{?dist}
Summary:        Python module for quantum chemistry
License:        ASL 2.0
URL:            https://github.com/pyscf/pyscf/
Source0:        https://github.com/pyscf/pyscf/archive/v%{version}/pyscf-%{version}.tar.gz

# Disable rpath
Patch1:         pyscf-1.7.0-rpath.patch

# ppc64 doesn't appear to have floats beyond 64 bits, so ppc64 is
# disabled as per upstream's request as for the libcint package.
ExcludeArch:    %{power64}

%if 0%{?is_opensuse}
BuildRequires:	libopenblas_openmp-devel
%else
BuildRequires:  %{blaslib}-devel
%endif
BuildRequires:  python3-devel
BuildRequires:	git
BuildRequires:  make

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:  python36-setuptools
BuildRequires:  devtoolset-8
BuildRequires:	devtoolset-8-gcc-c++
BuildRequires:  cmake3
BuildRequires:	python36-setuptools
%else
# Fedora > 30 && CentOS 8 && OpenSUSE
%if 0%{?is_opensuse}
# OpenSUSE
BuildRequires:  python3-setuptools
%else
# Fedora > 30 && CentOS 8
BuildRequires:  python3dist(setuptools)
%endif
%if 0%{?mdkver}
BuildRequires:  clang
BuildRequires:  glibc-devel
%else
BuildRequires:  gcc
BuildRequires:  gcc-c++
%endif
BuildRequires:  cmake
%endif

%global _description \
Python‐based simulations of chemistry framework (PySCF) is a		\
general‐purpose electronic structure platform designed from the ground	\
up to emphasize code simplicity, so as to facilitate new method		\
development and enable flexible computational workflows. The package	\
provides a wide range of tools to support simulations of finite‐size	\
systems, extended systems with periodic boundary conditions,		\
low‐dimensional periodic systems, and custom Hamiltonians, using	\
mean‐field and post‐mean‐field methods with standard Gaussian basis	\
functions. To ensure ease of extensibility, PySCF uses the Python	\
language to implement almost all of its features, while			\
computationally critical paths are implemented with heavily optimized	\
C routines. Using this combined Python/C implementation, the package	\
is as efficient as the best existing C or Fortran‐based quantum		\
chemistry programs.

%description %_description

%package -n python3-%{srcname}
Summary:        Python 3 module for quantum chemistry

%if (0%{?rhel} && 0%{?rhel} < 8) || 0%{?is_opensuse}
# CentOS 7
Requires:  	python3-numpy
Requires:  	python3-scipy < 1.5
Requires:  	python3-h5py > 2.2
%if 0%{?is_opensuse}
Requires:	openblas_openmp
%endif
%else
# Fedora > 30 && CentOS 8
Requires:	python3dist(numpy)
Requires:  	python3dist(scipy) < 1.5
Requires:  	python3dist(h5py) > 2.2
%endif

%description -n python3-%{srcname} %_description

%prep
%setup -q -n %{srcname}-%{version}
%patch1 -p1 -b .rpath

# Remove shebangs
find pyscf -name \*.py -exec sed -i '/#!\/usr\/bin\/env /d' '{}' \;
find pyscf -name \*.py -exec sed -i '/#!\/usr\/bin\/python/d' '{}' \;

%build

%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
%global cmake cmake3
scl enable devtoolset-8 -- <<\EOF
%else
%global cmake cmake
%endif

cd pyscf/lib
%{cmake} -DBUILD_LIBXC=ON -DENABLE_XCFUN=OFF -DBUILD_XCFUN=OFF \
      -DBUILD_LIBCINT=ON -DBLAS_LIBRARIES="-l%{blaslib}%{blasvar}" \
      -DCMAKE_SKIP_BUILD_RPATH=1
%{cmake} --build . --target libxc -- %{?_smp_mflags:%_smp_mflags}
%{cmake} --build . --target libcint -- %{?_smp_mflags:%_smp_mflags}
%{cmake} --build . -- %{?_smp_mflags:%_smp_mflags}

%if 0%{?rhel} && 0%{?rhel} < 8
EOF
%endif

%install
# Remove Python2 test files
rm -rfv %{buildroot}%{python3_sitearch}/pyscf/lib/deps/src/libcint/

# Remove build directory
rm -rf %{buildroot}%{python3_sitearch}/pyscf/lib/deps/src/libcint-build

# Package doesn't have an install command, so we do this by hand.
# Install all python sources
for f in $(find pyscf -name \*.py); do
    install -D -p -m 644 $f %{buildroot}%{python3_sitearch}/$f
done
# Install data files (mostly basis sets)
for f in $(find pyscf -name \*.dat); do
    install -D -p -m 644 $f %{buildroot}%{python3_sitearch}/$f
done
# Install compiled libraries
for f in $(find pyscf -name \*.so); do
    install -D -p -m 755 $f %{buildroot}%{python3_sitearch}/$f
done

# Remove Python2 test files
rm -rfv %{buildroot}%{python3_sitearch}/pyscf/lib/deps/src/libcint/testsuite

%{?py_byte_compile:%py_byte_compile %{__python3} %{buildroot}%{python3_sitearch}}

%check
export PYTHONPATH=$PWD
## While the program has tests, they take forever and won't ever finish
##on the build system.
#pytest

%files -n python3-%{srcname}
%license LICENSE
%doc CHANGELOG CONTRIBUTING.md FEATURES NOTICE README.md
%{python3_sitearch}/pyscf/
%if 0%{?mdkver}
%exclude /usr/lib/debug/
%exclude /usr/src/debug/
%endif

%changelog
* Sun Aug 16 2020 Iñaki Úcar <iucar@fedoraproject.org> - 1.7.4-2
- https://fedoraproject.org/wiki/Changes/FlexiBLAS_as_BLAS/LAPACK_manager

* Mon Aug 03 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.4-1
- Adapt to updated CMake scripts.
- Update to 1.7.4.

* Sat Aug 01 2020 Fedora Release Engineering <releng@fedoraproject.org> - 1.7.3-3
- Second attempt - Rebuilt for
  https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild

* Wed Jul 29 2020 Fedora Release Engineering <releng@fedoraproject.org> - 1.7.3-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild

* Thu Jun 11 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.3-1
- Update to 1.7.3.

* Tue May 26 2020 Miro Hrončok <mhroncok@redhat.com> - 1.7.2-2
- Rebuilt for Python 3.9

* Thu May 14 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.2-1
- Update to 1.7.2.

* Mon Apr 20 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.1-2
- Patch for libxc 5.

* Tue Mar 24 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.1-1
- Update to 1.7.1.

* Sun Feb 02 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.0-6
- Build against libopenblaso not libopenblas as the latter yields incorrect results.

* Thu Jan 30 2020 Fedora Release Engineering <releng@fedoraproject.org> - 1.7.0-5
- Rebuilt for https://fedoraproject.org/wiki/Fedora_32_Mass_Rebuild

* Thu Jan 23 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.0-4
- Switch buildrequire to libcint and disable build on ppc64.

* Thu Jan 23 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.0-3
- Filter provides and requires.

* Wed Jan 22 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.0-2
- Remove shebangs and rpath.

* Tue Jan 07 2020 Susi Lehtola <jussilehtola@fedoraproject.org> - 1.7.0-1
- First release.
