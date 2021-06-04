ppa_rev=1

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
	wget http://archive.ubuntu.com/ubuntu/pool/universe/m/matplotlib/matplotlib_${pkg_ver}.orig.tar.gz -P $root 1>&2
    fi
    echo $orig_tar_gz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control rules

    if [ "$ubuntu_distro_num" == "16.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
10
EOF
	sed -i -e '/python3-colorspacious/d' \
	    -e '/python3-ipywidgets/d' \
	    -e '/python3-pyqt4/d' \
	    -e '/python3-pyqt5/d' \
	    -e '/python3-sphinx-gallery/d' \
	    $pkg_dir/debian/control
	sed -i -e '/$(MAKE) -C doc html/d' \
	    -e  '/# build the doc/a\\tmkdir -p doc\/build\/html' \
	    -e '/export XDG_RUNTIME_DIR=\/tmp/a export DEB_BUILD_OPTIONS+=nocheck' \
	    $pkg_dir/debian/rules
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e '/ipython/d' \
	    $pkg_dir/debian/control
	sed -i -e '/$(MAKE) -C doc html/d' \
	    -e  '/# build the doc/a\\tmkdir -p doc\/build\/html' \
	    -e '/export XDG_RUNTIME_DIR=\/tmp/a export DEB_BUILD_OPTIONS+=nocheck' \
	    $pkg_dir/debian/rules
    else
	rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================
