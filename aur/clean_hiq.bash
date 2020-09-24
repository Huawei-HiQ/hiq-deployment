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
root=$HERE

# ==============================================================================

source $HERE/scripts/functions.bash

# ==============================================================================

pkg_list=$(ls | grep hiq-)

for pkg in $pkg_list; do
    pkgs=$(get_pkg_fnames $pkg)
    if [ -n "$pkgs" ]; then
	rm -rf $pkg/src
	rm -rf $pkg/pkg
	rm -f $pkg/*.tar.gz
	rm -f $pkg/*.tar.zst
    fi
done

# ==============================================================================
