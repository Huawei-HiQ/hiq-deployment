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

pacman --noconfirm -S archlinux-keyring
pacman --noconfirm -S base-devel git
pacman --noconfirm -Syu

useradd notroot
echo "notroot ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/notroot

# Wrapper function since makepkg cannot be run by root
makepkg_func()
{
    var="$@"
    sudo -u notroot -- sh -c "makepkg $var"
}
alias makepkg="makepkg_func"

makepkg --syncdeps --noconfirm
