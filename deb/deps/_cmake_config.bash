ppa_rev=6

# ==============================================================================

function pkg_download()
{
    local pkg_name=$1

    orig_tar_gz=$root/${pkg_name}_${pkg_ver}.orig.tar.gz
    if [ ! -f $orig_tar_gz ]; then
	wget http://archive.ubuntu.com/ubuntu/pool/main/c/${pkg_name}/${pkg_name}_${pkg_ver}.orig.tar.gz -P $root 1>&2
    fi
    echo $orig_tar_gz
}

# ------------------------------------------------------------------------------

function pkg_prepare()
{
    local pkg_dir=$1
    backup_files $pkg_dir control rules tests/testsuite
    if [ "$ubuntu_distro_num" == "16.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
10
EOF
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    -e '/python3-sphinx,/a \\t       python3-snowballstemmer,' \
	    $pkg_dir/debian/control

	sed -i -e "s/CTestTestUpload/'(CTestTestUpload|BootstrapTest|CTestCoverageCollectGCOV|RunCMake.File_Archive|RunCMake.CommandLineTar)'/" \
	    $pkg_dir/debian/rules

	sed -i -e 's/(CTestTestUpload|BootstrapTest)/(CTestTestUpload|BootstrapTest|CTestCoverageCollectGCOV|RunCMake.File_Archive|RunCMake.CommandLineTar)/' \
	    $pkg_dir/debian/tests/testsuite

    elif [ "$ubuntu_distro_num" == "18.04" ]; then
	cat << EOF > $pkg_dir/debian/compat
12
EOF
	sed -i -e 's/debhelper-compat (= 12)/debhelper/' \
	    $pkg_dir/debian/control

	sed -i -e "s/CTestTestUpload/'(CTestTestUpload|BootstrapTest|CTestCoverageCollectGCOV|RunCMake.File_Archive|RunCMake.CommandLineTar)'/" \
	    $pkg_dir/debian/rules

	sed -i -e 's/(CTestTestUpload|BootstrapTest)/(CTestTestUpload|BootstrapTest|CTestCoverageCollectGCOV|RunCMake.File_Archive|RunCMake.CommandLineTar)/' \
	    $pkg_dir/debian/tests/testsuite
    else
	rm -f $pkg_dir/debian/compat
    fi
}

# ==============================================================================

