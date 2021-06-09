ppa_rev=3

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1

    orig_tar_xz=$root/${pkg_name}_${pkg_ver}.orig.tar.xz
    if [ ! -f $orig_tar_xz ]; then
        wget http://archive.ubuntu.com/ubuntu/pool/main/i/${pkg_name}/${pkg_name}_${pkg_ver}.orig.tar.xz -P $root 1>&2
    fi

    echo $orig_tar_xz
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
        sed -i -e 's/debhelper (>= 11)/debhelper/' \
            $pkg_dir/debian/control
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
        cat << EOF > $pkg_dir/debian/compat
11
EOF
        # sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
        #     $pkg_dir/debian/control
    else
        cat << EOF > $pkg_dir/debian/compat
12
EOF
    fi
}

# ==============================================================================
