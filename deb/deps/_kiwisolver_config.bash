ppa_rev=1

# ==============================================================================

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control
    if [ "$ubuntu_distro_num" == "16.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
10
EOF
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    -e '/python3-matplotlib,/d' \
	    $pkg_dir/debian/control
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    -e '/python3-matplotlib,/d' \
	    $pkg_dir/debian/control
    else
	rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================

