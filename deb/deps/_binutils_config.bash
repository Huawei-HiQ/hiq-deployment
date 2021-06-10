ppa_rev=10

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1

    orig_tar_xz=$root/${pkg_name}_${pkg_ver}.orig.tar.xz
    if [ ! -f $orig_tar_xz ]; then
        wget http://archive.ubuntu.com/ubuntu/pool/main/b/${pkg_name}/${pkg_name}_${pkg_ver}.orig.tar.xz -P $root 1>&2
    fi

    echo $orig_tar_xz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control control.in rules

    if [ "$ubuntu_distro_num" == "16.04" ]; then
        cat << EOF > $pkg_dir/debian/compat
10
EOF
        sed -i -e 's/debhelper (>= 11)/debhelper/' \
            -e '/g++-i686-linux-gnu/d' \
            -e '/Package: binutils-i686-linux-gnu/,/ This package provides debug symbols for binutils-i686-linux-gnu./d' \
            -e '/Package: binutils-i686-gnu/,/This package provides debug symbols for binutils-i686-gnu./d' \
            -e '/Package: binutils-i686-kfreebsd-gnu/,/This package provides debug symbols for binutils-i686-kfreebsd-gnu./d' \
            $pkg_dir/debian/control

        sed -i -e 's/debhelper (>= 11)/debhelper/' \
            -e '/g++-i686-linux-gnu/d' \
            $pkg_dir/debian/control.in

        sed -i -e 's/dpkg-gensymbols -P$(d_ctf) -p$(p_ctf) -v2.33.50 -l$(d_lib)/dpkg-gensymbols -P$(d_ctf) -p$(p_ctf) -v2.33.50/' \
            $pkg_dir/debian/rules

    elif [ "$ubuntu_distro_num" == "18.04" ]; then
        cat << EOF > $pkg_dir/debian/compat
11
EOF
        sed -i -e 's/dpkg-gensymbols -P$(d_ctf) -p$(p_ctf) -v2.33.50 -l$(d_lib)/dpkg-gensymbols -P$(d_ctf) -p$(p_ctf) -v2.33.50/' \
            $pkg_dir/debian/rules
    else
        rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================
