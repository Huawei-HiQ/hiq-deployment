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

    orig_tar_gz=$root/python-${pkg_name}_$pkg_ver.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	wget http://archive.ubuntu.com/ubuntu/pool/universe/p/python-cycler/python-cycler_0.10.0.orig.tar.gz 1>&2
	mv -v python-cycler_0.10.0.orig.tar.gz $orig_tar_gz 1>&2
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
	sed -i -e 's/debhelper-compat (= 9)/debhelper/' \
	    -e '/python3-matplotlib,/d' \
	    $pkg_dir/debian/control
	sed -i -e '/PYBUILD_AFTER_BUILD/d' \
	    -e '/override_dh_installdocs:/a \\tmkdir -p doc/build/html' \
	    -e '/ln -s/d' \
	    $pkg_dir/debian/rules
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
10
EOF
	sed -i -e 's/debhelper-compat (= 9)/debhelper/' \
	    -e '/python3-matplotlib,/d' \
	    $pkg_dir/debian/control
    else
	rm -f $pkg_dir/debian/compat
    fi
}

# ------------------------------------------------------------------------------

function pkg_update_changelog()
{
    local pkg_dir=$1 ubuntu=$2 ubuntu_num=$3
    pkg_name=$(dpkg-parsechangelog -c 1 -l $pkg_dir/debian/changelog -S Source)
    version=$(gen_version $pkg_dir)
    
    dch -p \
	-c $pkg_dir/debian/changelog \
	-D $ubuntu --force-distribution \
	-v "$version" \
	PPA build
}

# ==============================================================================

