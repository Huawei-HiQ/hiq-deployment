ppa_rev=1

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1

    orig_tar_gz=$root/${pkg_name}_$pkg_ver.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	wget https://github.com/pandas-dev/pandas/archive/v$pkg_ver.tar.gz
	mv -v v$pkg_ver.tar.gz $orig_tar_gz 1>&2
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
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    -e '/<!nocheck>/d' \
	    -e '/<!nodoc>/d' \
	    -e '/Build-Depends-Indep:/a\ python3-sphinx,' \
	    $pkg_dir/debian/control
	sed -i -e '/find debian\/python3-scipy-dbg/d' \
	    -e '/export DEB_BUILD_MAINT_OPTIONS/a export DEB_BUILD_OPTIONS=nocheck nodoc' \
	    -e '/override_dh_installdocs:/a \\tmkdir -p doc/build/html' \
	    $pkg_dir/debian/rules
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    -e '/<!nocheck>/d' \
	    -e '/<!nodoc>/d' \
	    -e '/Build-Depends-Indep:/a\ python3-sphinx,' \
	    $pkg_dir/debian/control
	sed -i -e '/find debian\/python3-scipy-dbg/d' \
	    -e '/export DEB_BUILD_MAINT_OPTIONS/a export DEB_BUILD_OPTIONS=nocheck nodoc' \
	    -e '/override_dh_installdocs:/a \\tmkdir -p doc/build/html' \
	    $pkg_dir/debian/rules
    else
	rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================
