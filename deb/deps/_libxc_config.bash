ppa_rev=1

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1
    
    orig_tar_gz=$root/${pkg_name}_${pkg_ver}.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	wget http://archive.ubuntu.com/ubuntu/pool/universe/libx/${pkg_name}/${pkg_name}_${pkg_ver}.orig.tar.gz 1>&2
    fi
    echo $orig_tar_gz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1
    # backup_files $pkg_dir control rules
    if [ "$ubuntu_distro_num" == "16.04" ]; then
	:
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	:
    else
	:
    fi
}

# ==============================================================================

