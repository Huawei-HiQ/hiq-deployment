ppa_rev=1

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1

    orig_tar_xz=$root/${pkg_name}_${pkg_ver}.orig.tar.xz
    if [ ! -f $orig_tar_xz ]; then
        wget http://archive.ubuntu.com/ubuntu/pool/main/g/${pkg_name}-11/${pkg_name}-11_${pkg_ver}.orig.tar.gz -P $root 1>&2
        tar xvf $root/${pkg_name}-11_${pkg_ver}.orig.tar.gz -C $root
        rm $root/${pkg_name}-11_${pkg_ver}.orig.tar.gz
        mv $root/${pkg_name}-11-${pkg_ver}/${pkg_name}-${pkg_ver}.tar.xz $orig_tar_xz
    fi
    echo $orig_tar_xz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1
    # backup_files $pkg_dir control rules

    if [ "$ubuntu_distro_num" == "16.04" ]; then
        cat << EOF > $pkg_dir/debian/compat
10
EOF
        # sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
        #     -e '/python3-sphinx,/a \\t       python3-snowballstemmer,' \
        #     $pkg_dir/debian/control

        # sed -i -e "s/CTestTestUpload/'(CTestTestUpload|BootstrapTest|CTestCoverageCollectGCOV|RunCMake.File_Archive|RunCMake.CommandLineTar)'/" \
        #     $pkg_dir/debian/rules

    elif [ "$ubuntu_distro_num" == "18.04" ]; then
        cat << EOF > $pkg_dir/debian/compat
12
EOF
        # sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
        #     $pkg_dir/debian/control

        # sed -i -e "s/CTestTestUpload/'(CTestTestUpload|BootstrapTest|CTestCoverageCollectGCOV|RunCMake.File_Archive|RunCMake.CommandLineTar)'/" \
        #     $pkg_dir/debian/rules

    else
        rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================
