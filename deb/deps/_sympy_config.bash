pkg_archive_name=sympy-sympy
ppa_rev=2

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1 repo_url

    orig_tar_gz=$root/${pkg_name}_$pkg_ver.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	wget http://archive.ubuntu.com/ubuntu/pool/universe/s/sympy/sympy_$pkg_ver.orig.tar.gz -P $root 1>&2
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
	     -e '/python3-matplotlib/d' \
	     -e '/python3-distutils/d' \
	     -e '/texlive-/d' \
	     -e '/librsvg2-bin/d' \
	     -e '/imagemagick/d' \
	     -e '/inkscape/d' \
	     -e '/graphviz/d' \
	     -e '/dvipng/d' \
	     -e '/faketime/d' \
	    $pkg_dir/debian/control
	sed -i \
	    -e  '/faketime/,+1d' \
	    -e  '/\sdh_auto_build/a\\tmkdir -p doc/_build/html' \
	    $pkg_dir/debian/rules
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    $pkg_dir/debian/control
	sed -i \
	    -e  '/faketime/,+1d' \
	    -e  '/\sdh_auto_build/a\\tmkdir -p doc/_build/html' \
	    $pkg_dir/debian/rules
    else
	rm -f $pkg_dir/debian/compat
    fi
}


# ------------------------------------------------------------------------------

function pkg_update_changelog()
{
    local pkg_dir=$1 ubuntu=$2 ubuntu_num=$3
    pkg_name=$(dpkg-parsechangelog -c 1 -l $pkg_dir/debian/changelog -S Source)

    if [[ "$ubuntu_num" == 16.04 ]]; then
	version=$(gen_version $pkg_dir $ubuntu_num)
	dch -p \
	    -c $pkg_dir/debian/changelog \
	    -D $ubuntu --force-distribution \
	    -v "$version" \
	    Ubuntu $ubuntu build
    else
	version=$(gen_version $pkg_dir)
	dch -p \
	    -c $pkg_dir/debian/changelog \
	    -D $ubuntu --force-distribution \
	    -v "$version" \
	    PPA build
    fi
}

# ==============================================================================

