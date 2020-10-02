ppa_rev=1

# ==============================================================================

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control rules

    if [ "$ubuntu_distro_num" == "16.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
10
EOF
	sed -i -e 's/debhelper-compat (= 13)/debhelper/' \
	    $pkg_dir/debian/control

	doc1='mkdir -p docs\/source\/usrman\/_build\/man'
	doc2='mkdir -p docs\/source\/usrman\/_build\/html'
	doc3='touch docs\/source\/usrman\/_build\/man/mpi4py.1'
	
	sed -i -e '/override_dh_auto_build-indep:/,+2d' \
	    -e "/override_dh_auto_install/i override_dh_auto_build-indep: override_dh_auto_build-arch\n\t$doc1\n\t$doc2\n\t$doc3\n" \
	    -e 's#.pybuild/cpython$${v}_$${vv}#.pybuild/*python*_$${vv}#' \
	    $pkg_dir/debian/rules
    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e 's/debhelper-compat (= 13)/debhelper/' \
	    $pkg_dir/debian/control
    else
	rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================
