#! /bin/bash
# ==============================================================================
#
# Copyright 2020 <Huawei Technologies Co., Ltd>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ==============================================================================

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
os_name=$(cat /etc/os-release | grep ID= | sort | head -n1 | cut -d '=' -f2 | tr -d '"')
os_ver=$(cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2 | tr -d '"')

# You might need to rename and edit setup_env.bash.in 
. setup_env.bash

apt update

ln -snf /usr/share/zoneinfo/$(curl https://ipapi.co/timezone) /etc/localtime
apt install -y tzdata

apt upgrade -y
apt dist-upgrade -y

apt install -y curl software-properties-common
add-apt-repository -y -u ppa:huawei-hiq/base-packages
add-apt-repository -y -u ppa:huawei-hiq/ppa
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9071AE544115FB0C

apt update
apt install -y build-essential devscripts pbuilder lintian sbuild cdbs debhelper quilt dh-make dh-python fakeroot apt-src python3-pip equivs git

if [[ "$os_name" == "ubuntu" ]]; then
    if [[ "$os_ver" == 16.04 ]]; then
	apt install -y gnupg2
	sudo mv /usr/bin/gpg /usr/bin/gpg1
	sudo update-alternatives --verbose --install /usr/bin/gpg gnupg /usr/bin/gpg2 50

    fi
fi

if [ -f $HERE/private.key ]; then
    gpg --import $HERE/private.key
fi

python3 - << \EOF
import re
import os

def add_deb_src(fname):
    lines_new = []
    with open(fname, 'r') as fd:
        lines = fd.readlines()
        for line in lines:
            if line.startswith('#'):
                lines_new.append(line)
            else:
                if line not in lines_new:
                    lines_new.append(line)

                line_new = re.sub('^deb(?!-src)', 'deb-src', line)
                if line_new != line:
                    lines_new.append(line_new)

    with open(fname, 'w') as fd:
        fd.writelines(lines_new)
            

add_deb_src('/etc/apt/sources.list')

apt_source_d = '/etc/apt/sources.list.d'
for apt_source in os.listdir('/etc/apt/sources.list.d'):
    add_deb_src(os.path.join(apt_source_d, apt_source))
EOF

apt-src update

cat << \EOF > /usr/local/bin/dquilt
quilt --quiltrc=${HOME}/.quiltrc-dpkg "$@"
EOF
chmod 755 /usr/local/bin/dquilt

complete -F _quilt_completion $_quilt_complete_opt dquilt

cat << \EOF > ~/.quiltrc-dpkg
d=.
while [ ! -d $d/debian -a `readlink -e $d` != / ];
    do d=$d/..; done
if [ -d $d/debian ] && [ -z $QUILT_PATCHES ]; then
    # if in Debian packaging tree with unset $QUILT_PATCHES
    QUILT_PATCHES="debian/patches"
    QUILT_PATCH_OPTS="--reject-format=unified"
    QUILT_DIFF_ARGS="-p ab --no-timestamps --no-index --color=auto"
    QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index"
    QUILT_COLORS="diff_hdr=1;32:diff_add=1;34:diff_rem=1;31:diff_hunk=1;33:diff_ctx=35:diff_cctx=33"
    if ! [ -d $d/debian/patches ]; then mkdir $d/debian/patches; fi
fi
EOF

cat << EOF > ~/.devscripts
DEBUILD_DPKG_BUILDPACKAGE_OPTS="-i -I -us -uc"
DEBUILD_LINTIAN_OPTS="-i -I --show-overrides"
DEBSIGN_KEYID="$GPG_KEY"
EOF

cat << \EOF > ~/.pbuilderrc
AUTO_DEBSIGN="${AUTO_DEBSIGN:-no}"
PDEBUILD_PBUILDER=cowbuilder
HOOKDIR="/var/cache/pbuilder/hooks"
MIRRORSITE="http://deb.debian.org/debian/"
#APTCACHE=/var/cache/pbuilder/aptcache
APTCACHE=/var/cache/apt/archives
#BUILDRESULT=/var/cache/pbuilder/result/
BUILDRESULT=../
EXTRAPACKAGES="ccache lintian libeatmydata1"

# enable to use libeatmydata1 for pbuilder
#export LD_PRELOAD=${LD_PRELOAD+$LD_PRELOAD:}libeatmydata.so

# enable ccache for pbuilder
#export PATH="/usr/lib/ccache${PATH+:$PATH}"
#export CCACHE_DIR="/var/cache/pbuilder/ccache"
#BINDMOUNTS="${CCACHE_DIR}"

# parallel make
#DEBBUILDOPTS=-j4
EOF

mkdir -p /var/cache/pbuilder/hooks/
cat << \EOF > /var/cache/pbuilder/hooks/B90lintian
#!/bin/sh
set -e
apt-get -y --allow-downgrades install lintian
echo "+++ lintian output +++"
su -c "lintian -i -I --show-overrides /tmp/buildd/*.changes; :" -l pbuilder
echo "+++ end of lintian output +++"
EOF

cat << \EOF > /var/cache/pbuilder/hooks/C10shell
#!/bin/sh
set -e
apt-get -y --allow-downgrades install vim bash mc
# invoke shell if build fails
cd /tmp/buildd/*/debian/..
/bin/bash < /dev/tty > /dev/tty 2> /dev/tty
EOF

cat << \EOF > ~/.gbp.conf
# Configuration file for "gbp <command>"

[DEFAULT]
# the default build command:
builder = git-pbuilder -i -I -us -uc
# use pristine-tar:
pristine-tar = True
# Use color when on a terminal, alternatives: on/true, off/false or auto
color = auto
EOF

add-apt-repository -y ppa:huawei-hiq/ppa
apt-get update
