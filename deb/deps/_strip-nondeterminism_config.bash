ppa_rev=1

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1

    orig_tar_bz2=$root/${pkg_name}_${pkg_ver}.orig.tar.bz2
    if [ ! -f $orig_tar_bz2 ]; then
        wget http://archive.ubuntu.com/ubuntu/pool/main/s/${pkg_name}/${pkg_name}_${pkg_ver}.orig.tar.bz2 -P $root 1>&2
    fi
    tar xvf $orig_tar_bz2 -C $root 1>&2
    rm -rf $root/${pkg_name}-$pkg_ver/debian
    echo $orig_tar_bz2
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

        sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
            $pkg_dir/debian/control

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
