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

rm -fv $HERE/*.build
rm -fv $HERE/*.buildinfo
rm -fv $HERE/*_source.ppa.upload
rm -fv $HERE/*_amd64.changes
rm -fv $HERE/*-debian.tar.gz

rm -fv $HERE/*.dsc
rm -fv $HERE/*_source.changes
rm -fv $HERE/*.debian.tar.xz
