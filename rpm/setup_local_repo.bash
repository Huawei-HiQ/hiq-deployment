os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')

yum install -y createrepo
if [ "$os_name" == "centos" ]; then
    yum install -y epel-release
    if [ $os_ver -eq 7 ]; then
	yum install -y yum-plugin-priorities centos-release-scl
    fi
fi

repo_root=/share/CentOS/$os_ver/local

mkdir -p $repo_root/x86_64/RPMS

cat << \EOF > /etc/yum.repos.d/local.repo
[local]
name=CentOS-$releasever - local packages for $basearch
baseurl=file:///share/CentOS/$releasever/local/$basearch
enabled=1
gpgcheck=0
priority=10
EOF

copy_to_local_repo()
{
    /bin/cp -v "$@" $repo_root/x86_64/RPMS
    update_local_repo
}

update_local_repo()
{
    chown -R root.root $repo_root
    createrepo $repo_root/x86_64
    chmod -R o-w+r $repo_root
    touch /etc/yum.repos.d/local.repo
    yum check-update
}

# Required to initialize the local repo (even if empty)
update_local_repo

# copy_to_local_repo *.rpm
# update_local_repo
