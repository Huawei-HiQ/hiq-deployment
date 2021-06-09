ppa_rev=3

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1

    orig_tar_xz=$root/${pkg_name}_${pkg_ver}ubuntu1.tar.xz
    if [ ! -f $orig_tar_xz ]; then
        wget http://archive.ubuntu.com/ubuntu/pool/main/d/${pkg_name}/${pkg_name}_${pkg_ver}ubuntu1.tar.xz -P $root 1>&2
    fi
    tar xvf $root/${pkg_name}_${pkg_ver}ubuntu1.tar.xz -C $root 1>&2
    mv -v $root/${pkg_name}-${pkg_ver}ubuntu1 $root/${pkg_name}-${pkg_ver} 1>&2
    echo $orig_tar_xz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1

    if [ "$ubuntu_distro_num" == "16.04" ]; then
        cat << EOF > $pkg_dir/debian/compat
10
EOF

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
