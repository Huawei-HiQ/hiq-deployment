# ==============================================================================


pkg_dir=$(basename $(ls -d $templates_dir/* | grep $pkg | sort | tr ' ' '\n' | tail -n1))
if [ -z "$pkg_dir" ]; then
    die "Missing folder in $templates_dir!"
fi

pkg_name=$pkg
pkg_ver=${pkg_dir##$pkg-}

if [ -f $config_dir/_${pkg_name}_config.bash ]; then
    source $config_dir/_${pkg_name}_config.bash
else
    ppa_rev=1
fi

pkg_dir=$root/$pkg_dir

# ------------------------------------------------------------------------------
# Cleanup?

if [ $clean_dirs -eq 1 ]; then
    dir=$backup_dir/$(basename $pkg_dir)
    if [ -d $dir ]; then
	echo "Cleaning $dir"
	rm -rf $dir
    fi

    dir=$pkg_dir
    if [ -d $dir ]; then
	echo "Cleaning $dir"
	rm -rf $dir
    fi

    file=$root/${pkg_name}*orig*
    if [ -f $file ]; then
	rm -vf $file
    fi
    file=$root/python-${pkg_name}*orig*
    if [ -f $file ]; then
	rm -vf $file
    fi

    if [ $clean_only -eq 1 ]; then
	exit 0
    fi
fi

# ------------------------------------------------------------------------------
# Setup source directory

archive_name=$(pkg_download $pkg_name $pkg_archive_name)
if [ ! -d $pkg_dir ]; then
    echo tar xvf $archive_name -C $root
    tar xvf $archive_name -C $root

    if [ ! -d $pkg_dir ]; then
	if [ -z "$pkg_archive_name" ]; then
	    pkg_archive_name=$pkg_name
	fi
	mv -v $root/${pkg_archive_name}-$pkg_ver $pkg_dir
    fi
fi

# ==============================================================================
