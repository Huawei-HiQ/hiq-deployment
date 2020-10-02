ppa_rev=1

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1
    
    orig_tar_gz=$root/python-snowballstemmer_${pkg_ver}.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	wget http://archive.ubuntu.com/ubuntu/pool/universe/p/python-snowballstemmer/python-snowballstemmer_${pkg_ver}.orig.tar.gz 1>&2
    fi
    echo $orig_tar_gz
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

