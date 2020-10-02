ppa_rev=2

# ==============================================================================

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control rules

    if [ "$ubuntu_distro_num" == "16.04" ]; then
	sed -i -e '/Build-Depends-Indep/a\ python3-snowballstemmer,' \
	    $pkg_dir/debian/control
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	:
    else
	:
    fi
}

# ==============================================================================
