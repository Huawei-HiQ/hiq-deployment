ppa_rev=2

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1

    orig_tar_xz=$root/${pkg_name}_${pkg_ver}.orig.tar.xz
    if [ ! -f $orig_tar_xz ]; then
        wget http://archive.ubuntu.com/ubuntu/pool/main/d/${pkg_name}/${pkg_name}_${pkg_ver}.tar.xz -P $root 1>&2
        tar xvf $root/${pkg_name}_${pkg_ver}.tar.xz -C $root
        mv -v $root/${pkg_name}-19 $root/${pkg_name}-${pkg_ver}
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

        sed -i -e 's/debhelper (>= 11)/debhelper/' \
            $pkg_dir/debian/control

    elif [ "$ubuntu_distro_num" == "18.04" ]; then
        cat << EOF > $pkg_dir/debian/compat
12
EOF

    else
        rm -f $pkg_dir/debian/compat
    fi
}

# ------------------------------------------------------------------------------

function pkg_move_results()
{
    local pkg=$1 output_dir=$2
    pkg_dir=$(basename $(ls -d $templates_dir/* | sort -r | grep $pkg))
    if [ -z "$pkg_dir" ]; then
        die "Missing folder in $templates_dir!"
    fi
    pkg_name=$pkg
    pkg_ver=${pkg_dir##$pkg-}
    pkg_dir=$root/$pkg_dir

    version=$(get_version $pkg_dir)

    mkdir -p $output_dir

    fargs=($root/${pkg_name}_${version}.debian.tar.xz
           $root/python-${pkg_name}_${version}.debian.tar.xz
           $root/${pkg_name}_${version}.dsc
           $root/python-${pkg_name}_${version}.dsc
           $root/${pkg_name}_${version}_source.changes
           $root/python-${pkg_name}_${version}_source.changes
           $root/${pkg_name}_${version}_source.build
           $root/python-${pkg_name}_${version}_source.build
           $root/${pkg_name}_${version}_source.buildinfo
           $root/python-${pkg_name}_${version}_source.buildinfo)
    for file in "${fargs[@]}"; do
        if [ -f $file ]; then
            mv -v $file $output_dir
        fi
    done

    fargs=($root/${pkg_name}_${version}.tar.xz)
    for file in "${fargs[@]}"; do
        if [ -f $file ]; then
            cp -v $file $output_dir
        fi
    done
}

# ==============================================================================
