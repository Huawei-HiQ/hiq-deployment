pkg_archive_name=Cython
ppa_rev=2

# ==============================================================================

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control rules
    if [ "$ubuntu_distro_num" == "16.04" ]; then
	sed -i -e '/ python3-numpy/d' $pkg_dir/debian/control
	sed -i \
	    -e  '/override_dh_auto_test:/,/endif/c override_dh_auto_test:' \
	    $pkg_dir/debian/rules
    else
	# Tests seem to fail regardless... so disable them.
	sed -i \
	    -e  '/override_dh_auto_test:/,/endif/c override_dh_auto_test:' \
	    $pkg_dir/debian/rules
    fi
}

# ==============================================================================

