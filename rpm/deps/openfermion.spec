%global srcname openfermion
%global of_version 0.11.0
%global of_projectq_version 0.2

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
Version:        %{of_version}
Release:        1%{?dist}
Summary:        The electronic structure package for quantum computers.
License:        Apache-2.0
URL:            https://github.com/quantumlib/OpenFermion
Source0:	https://files.pythonhosted.org/packages/source/o/%{srcname}/%{srcname}-%{version}.tar.gz
Source1:	https://files.pythonhosted.org/packages/source/o/openfermionprojectq/openfermionprojectq-0.2.tar.gz

Patch0:		openfermion-remove-non-ascii-char-in-readme.patch
BuildArch:      noarch

BuildRequires:  python3-devel
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
BuildRequires:	python36-setuptools
%else
# Fedora > 30 && CentOS > 7 && OpenSUSE
BuildRequires:	python3-setuptools
%endif

%define requirements				\
%if 0%{?rhel} && 0%{?rhel} < 8			\
# CentOS 7					\
Requires:     	python36-numpy > 1.11.0		\
Requires:     	python36-scipy > 1.1.0		\
Requires:     	python36-networkx > 2.0		\
Requires:	python36-h5py >= 2.8		\
Requires:  	python36-requests >= 2.18	\
Requires:  	python36-requests < 3		\
Requires:	python36-pubchempy  		\
%else						\
# Fedora > 30 && CentOS > 7			\
Requires:     	python3-numpy > 1.11.0		\
Requires:     	python3-scipy > 1.1.0		\
Requires:     	python3-networkx > 2.0		\
Requires:	python3-h5py >= 2.8		\
Requires:  	python3-requests >= 2.18	\
Requires:  	python3-requests < 3		\
Requires:	python3-pubchempy  		\
%endif

%requirements

%global _description \
OpenFermion is an open source library for compiling and analyzing quantum \
algorithms to simulate fermionic systems, including quantum chemistry. Among \
other functionalities, this version features data structures and tools for \
obtaining and manipulating representations of fermionic and qubit \
Hamiltonians. For more information, see our release paper.

%description %_description

%package -n python3-%{srcname}
Summary:        %{summary}
%{?python_provide:%python_provide python3-%{srcname}}
%requirements

%description -n python3-%{srcname} %_description

# ==============================================================================

%package -n python3-%{srcname}projectq
Summary:        A plugin allowing OpenFermion to interaface with ProjectQ.
Provides:       python3-openfermionprojectq = %{of_projectq_version}-%{release}
%{?python_provide:%python_provide python3-%{srcname}projectq}
Requires:	python3-%{srcname} == %{version}-%{release}
%if 0%{?rhel} && 0%{?rhel} < 8
# CentOS 7
Requires:	python3-hiq-projectq
%else
Requires:	python3dist(hiq-projectq)
%endif

%description -n python3-%{srcname}projectq

OpenFermion is an open source package for compiling and analyzing quantum
algorithms that simulate fermionic systems. This plugin library allows the
circuit simulation and compilation package ProjectQ to interface with
OpenFermion.

# ==============================================================================

%prep
%setup -q -n %{srcname}-%{version} -a1

cd %{srcname}projectq-%{of_projectq_version}
%patch0 -p1


%build

%if 0%{?fedora} && 0%{?fedora} > 30
# Fedora > 30 apparently reads the requirements.txt file
sed -ie 's/~=2.18/>=2.18,<3/' requirements.txt
%endif

%py3_build
cd %{srcname}projectq-%{of_projectq_version}
%py3_build


%install
%py3_install
cd %{srcname}projectq-0.2
%py3_install

%{?py_byte_compile:%py_byte_compile %{__python3} %{buildroot}%{python3_sitelib}}

%files -n python3-%{srcname}
%defattr(-,root,root,-)
%{python3_sitelib}/openfermion-%{version}-py%{python3_version}.egg-info
%{python3_sitelib}/openfermion
%{_prefix}/openfermion

%files -n python3-%{srcname}projectq
%defattr(-,root,root,-)
%{python3_sitelib}/openfermionprojectq-%{of_projectq_version}-py%{python3_version}.egg-info
%{python3_sitelib}/openfermionprojectq

%changelog
* Tue Sep 15 2020 Damien Nguyen <damien1@hauwei.com> - 0.11-1
- Initial build.

