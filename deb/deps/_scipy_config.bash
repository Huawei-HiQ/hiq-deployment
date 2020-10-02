ppa_rev=2

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1 repo_url
    repo_url=https://salsa.debian.org/python-team/modules/scipy.git


    tag_ver=$(basename $(git ls-remote --tags $repo_url \
			     | grep debian/ | grep $pkg_ver | cut -f2))

    git clone --depth 1 --branch debian/$tag_ver $repo_url $pkg_dir

    orig_tar_gz=$root/${pkg_name}_$pkg_ver.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	wget https://github.com/scipy/scipy/releases/download/v${pkg_ver}/${pkg_name}-${pkg_ver}.tar.gz 1>&2
	mv -v ${pkg_name}-$pkg_ver.tar.gz $orig_tar_gz 1>&2
    fi
    echo $orig_tar_gz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control rules patches/series patches/Use-system-LBFGSB.patch

    if [ "$ubuntu_distro_num" == "16.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
10
EOF
	sed -i -e '/Use-system-LBFGSB.patch/d' $pkg_dir/debian/patches/series
	rm -f $pkg_dir/debian/patches/Use-system-LBFGSB.patch
	rm -f $pkg_dir/scipy/optimize/setup.py
	rm -f $pkg_dir/scipy/optimize/tests/test_optimize.py

	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    -e '/liblbfgsb-dev/d' \
	    -e '/python3-all-dbg/d' \
	    -e '/python3-numpy-dbg/d' \
	    -e '/python3-matplotlib/d' \
	    -e '/python3-docutils/d' \
	    -e '/rdfind/d' \
	    -e '/symlinks/d' \
	    -e '/texlive/d' \
	    -e  '/Package: python3-scipy-dbg/,/ This package provides debugging symbols for python3-scipy./d' \
	    -e  '/Depends: fonts-open-sans/,/         ${sphinxdoc:Depends}/d' \
	    $pkg_dir/debian/control
	sed -i -e '/find debian\/python3-scipy-dbg/d' \
	    -e '/export PYBUILD_NAME=scipy/a export DEB_BUILD_OPTIONS=nocheck' \
	    -e '/CFLAGS="-g -ggdb"/d' \
	    -e '/dbg --configure --configure-args/d' \
	    -e  's/dh_strip -ppython3-scipy --dbg-package=python3-scipy-dbg/dh_strip -ppython3-scipy/' \
	    -e '/dh_sphinxdoc/d' \
	    -e '/find debian\/python-scipy-doc/d' \
	    -e '/rdfind -outputname/d' \
	    -e '/symlinks -r -s -c/d' \
	    -e '/_shgo_lib\/sobol_vec.gz/d' \
	    -e 's/PYTHONPATH=$$PYLIBPATH make -C doc html PYTHONPATH=$$PYLIBPATH PYVER=3)/mkdir -p doc\/build\/html)/' \
	    $pkg_dir/debian/rules
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    -e '/python3-all-dbg/d' \
	    -e '/python3-numpy-dbg/d' \
	    -e '/python3-sphinx/d' \
	    -e '/python3-numpydoc/d' \
	    -e '/python3-matplotlib/d' \
	    -e '/python3-docutils/d' \
	    -e '/rdfind/d' \
	    -e '/symlinks/d' \
	    -e '/texlive/d' \
	    -e  '/Package: python3-scipy-dbg/,/ This package provides debugging symbols for python3-scipy./d' \
	    -e  '/Depends: fonts-open-sans/,/         ${sphinxdoc:Depends}/d' \
	    $pkg_dir/debian/control
	sed -i -e '/find debian\/python3-scipy-dbg/d' \
	    -e '/CFLAGS="-g -ggdb"/d' \
	    -e '/dbg --configure --configure-args/d' \
	    -e  's/dh_strip -ppython3-scipy --dbg-package=python3-scipy-dbg/dh_strip -ppython3-scipy/' \
	    -e '/dh_sphinxdoc/d' \
	    -e '/find debian\/python-scipy-doc/d' \
	    -e '/rdfind -outputname/d' \
	    -e '/symlinks -r -s -c/d' \
	    -e 's/PYTHONPATH=$$PYLIBPATH make -C doc html PYTHONPATH=$$PYLIBPATH PYVER=3)/mkdir -p doc\/build\/html)/' \
	    $pkg_dir/debian/rules
    else
	rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================
