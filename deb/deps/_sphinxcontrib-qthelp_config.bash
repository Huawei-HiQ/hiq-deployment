ppa_rev=1

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1
    
    orig_tar_gz=$root/${pkg_name}_${pkg_ver}.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	wget http://archive.ubuntu.com/ubuntu/pool/universe/s/${pkg_name}/${pkg_name}_${pkg_ver}.orig.tar.gz 1>&2	
    fi
    echo $orig_tar_gz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control rules patches/series
    if [ "$ubuntu_distro_num" == "16.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
10
EOF
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    -e 's/libext2fs-dev/e2fslibs-dev/' \
	    $pkg_dir/debian/control
	sed -i -e '/export PYBUILD_NAME/i export DEB_BUILD_OPTIONS=nocheck/' \
	    $pkg_dir/debian/rules
	cat << EOF >> $pkg_dir/debian/patches/series
remove-non-utf8-chars.patch
EOF
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    $pkg_dir/debian/control
    else
	rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================

