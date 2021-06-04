ppa_rev=3

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1 repo_url
    repo_url=https://salsa.debian.org/python-team/modules/requests.git

    tag_ver=$(basename $(git ls-remote --tags $repo_url \
			     | grep debian/ | grep $pkg_ver | head -n1 | cut -f2))

    git clone --depth 1 --branch debian/$tag_ver $repo_url $pkg_dir

    orig_tar_xz=$root/${pkg_name}_$pkg_ver.orig.tar.xz
    if [ ! -f $orig_tar_xz ]; then
	wget http://archive.ubuntu.com/ubuntu/pool/main/r/${pkg_name}/${pkg_name}_2.23.0+dfsg.orig.tar.xz -P $root 1>&2
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
