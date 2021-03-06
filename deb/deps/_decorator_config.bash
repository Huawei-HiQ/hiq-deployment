ppa_rev=1

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1
    if [ $# -gt 1 ]; then
	pkg_archive_name=$2
    else
	pkg_archive_name=$pkg_name
    fi

    orig_tar_gz=$root/python-${pkg_name}_$pkg_ver.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	python3 -m pip download --no-binary ":all:" "$pkg_name==$pkg_ver" --no-deps 1>&2
	mv -v ${pkg_archive_name}-$pkg_ver.tar.gz $orig_tar_gz 1>&2
    fi
    echo $orig_tar_gz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    :
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

