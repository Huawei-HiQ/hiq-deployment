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

pacman --noconfirm -Syu
pacman --noconfirm -S archlinux-keyring
pacman --noconfirm -S base-devel git namcap

useradd notroot
echo "notroot ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/notroot

# Wrapper function since makepkg cannot be run by root
makepkg_func()
{
    var="$@"
    sudo -u notroot -- sh -c "makepkg $var"
}
alias makepkg=makepkg_func

# Auto-fetch GPG keys (for checking signatures):
mkdir ~/.gnupg && \
    touch ~/.gnupg/gpg.conf && \
    echo "keyserver-options auto-key-retrieve" > ~/.gnupg/gpg.conf

mkdir -p /home/notroot
chown -R notroot /home/notroot

cat << \EOF > /usr/local/bin/makepkg
#! /bin/bash
var="$@"
sudo -u notroot -- sh -c "/usr/bin/makepkg $var"
EOF
chmod 755 /usr/local/bin/makepkg

# ------------------------------------------------------------------------------

pushd /tmp
# Install yay (for building AUR dependencies):
git clone https://aur.archlinux.org/yay-bin.git && \
    chown -R notroot yay-bin && cd yay-bin && \
    makepkg --noconfirm --syncdeps --rmdeps --install --clean && \
    cd .. && rm -rf yay-bin
popd

cat << \EOF > /usr/local/bin/yay
#! /bin/bash
var="$@"
sudo -u notroot -- sh -c "/usr/sbin/yay $var"
EOF
chmod 755 /usr/local/bin/yay

# ==============================================================================
