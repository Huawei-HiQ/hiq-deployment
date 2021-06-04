ppa_rev=1

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1

    orig_tar_xz=$root/${pkg_name}_${pkg_ver}.orig.tar.xz
    if [ ! -f $orig_tar_xz ]; then
	wget http://archive.ubuntu.com/ubuntu/pool/main/liba/${pkg_name}/${pkg_name}_${pkg_ver}.orig.tar.xz -P $root 1>&2
    fi
    echo $orig_tar_xz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control
    if [ "$ubuntu_distro_num" == "16.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
10
EOF
	sed -i -e 's/debhelper-compat (= 13)/debhelper/' \
	    -e 's/libext2fs-dev/e2fslibs-dev/' \
	    $pkg_dir/debian/control
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e 's/debhelper-compat (= 13)/debhelper/' \
	    $pkg_dir/debian/control
    else
	rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================

