pkg_archive_name=Sphinx
ppa_rev=1

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1
    if [ $# -gt 1 ]; then
	pkg_archive_name=$2
    else
	pkg_archive_name=$pkg_name
    fi

    orig_tar_gz=$root/${pkg_name}_$pkg_ver.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	wget http://archive.ubuntu.com/ubuntu/pool/main/s/sphinx/sphinx_3.2.1.orig.tar.gz 1>&2
	mv -v sphinx_3.2.1.orig.tar.gz $orig_tar_gz 1>&2
    fi
    echo $orig_tar_gz
    
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control rules patches/series patches/no_snowballstemmer.diff
    if [ "$ubuntu_distro_num" == "16.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
10
EOF
	sed -i -e 's/debhelper-compat (= 13)/debhelper/' \
	    -e 's/dh-python (>= 3.20180313~)/dh-python/' \
	    -e '/python3-sphinxcontrib.websupport/d' \
	    -e '/python3-lib2to3/d' \
	    -e '/python3-distutils/d' \
	    $pkg_dir/debian/control
	sed -i -e '/no_snowballstemmer.diff/d' \
	    $pkg_dir/debian/patches/series
	sed -i \
	    -e  '/py3_builddir =/d' \
	    -e  '/py3_libdir =/a py3_builddir = $(shell ls -d .pybuild/*/build | sort | head -n1)' \
	    -e '/python3 setup.py compile_catalog/d' \
	    -e '/override_dh_installchangelogs:/i override_dh_auto_test:\n\techo "Pass"' \
	    -e '/LC_MESSAGES\/sphinx.js/,+1d' \
	    -e '/override_dh_auto_install:/a \\tmkdir -p $(debroot)/usr/share/sphinx/locale/' \
	    $pkg_dir/debian/rules
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e 's/debhelper-compat (= 13)/debhelper/' \
	    -e 's/dh-python (>= 3.20180313~)/dh-python/' \
	    -e '/python3-sphinxcontrib.websupport/d' \
	    -e '/python3-lib2to3/d' \
	    -e '/python3-distutils/d' \
	    $pkg_dir/debian/control
	sed -i -e '/no_snowballstemmer.diff/d' \
	    $pkg_dir/debian/patches/series
	sed -i \
	    -e  '/py3_builddir =/d' \
	    -e  '/py3_libdir =/a py3_builddir = $(shell ls -d .pybuild/*/build | sort | head -n1)' \
	    -e '/python3 setup.py compile_catalog/d' \
	    -e '/override_dh_installchangelogs:/i override_dh_auto_test:\n\techo "Pass"' \
	    -e '/LC_MESSAGES\/sphinx.js/,+1d' \
	    -e '/override_dh_auto_install:/a \\tmkdir -p $(debroot)/usr/share/sphinx/locale/' \
	    $pkg_dir/debian/rules
    elif [ "$ubuntu_distro_num" == "20.04" ]; then
	rm -f $pkg_dir/debian/compat
	sed -i -e 's/debhelper-compat (= 13)/debhelper-compat (= 12)/' \
	    $pkg_dir/debian/control
	sed -i -e '/diff --git a\/Sphinx.egg-info\/requires.txt b\/Sphinx.egg-info\/requires.txt/,/ imagesize/d' \
	    $pkg_dir/debian/patches/no_snowballstemmer.diff
    else 
	rm -f $pkg_dir/debian/compat
	sed -i -e '/diff --git a\/Sphinx.egg-info\/requires.txt b\/Sphinx.egg-info\/requires.txt/,/ imagesize/d' \
	    $pkg_dir/debian/patches/no_snowballstemmer.diff
    fi
}

# ------------------------------------------------------------------------------

function pkg_update_changelog()
{
    local pkg_dir=$1 ubuntu=$2 ubuntu_num=$3
    pkg_name=$(dpkg-parsechangelog -c 1 -l $pkg_dir/debian/changelog -S Source)

    if [[ "$ubuntu_num" == 16.04 ]]; then
	version=$(gen_version $pkg_dir $ubuntu_num)
	dch -p \
	    -c $pkg_dir/debian/changelog \
	    -D $ubuntu --force-distribution \
	    -v "$version" \
	    Ubuntu $ubuntu build
    else
	version=$(gen_version $pkg_dir)
	dch -p \
	    -c $pkg_dir/debian/changelog \
	    -D $ubuntu --force-distribution \
	    -v "$version" \
	    PPA build
    fi
}

# ==============================================================================

