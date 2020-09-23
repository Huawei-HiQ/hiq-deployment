# frozen_string_literal: true

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

class HiqFermion < Formula
  include Language::Python::Virtualenv

  desc "Huawei-HiQ Fermion"
  homepage "https://hiq.huaweicloud.com/en/"
  url "https://pypi.io/packages/source/h/hiq-fermion/hiq-fermion-0.0.1.post2.tar.gz"
  version "0.0.1"
  sha256 "XXXXXXXXX"
  license "Apache-2.0"
  revision 2

  depends_on "llvm"
  depends_on "numpy"
  depends_on "python@3.8"
  depends_on "scipy"

  def install
    version = Language::Python.major_minor_version Formula["python@3.8"].opt_bin/"python3"
    site_packages = "lib/python#{version}/site-packages"

    venv = virtualenv_create(libexec, Formula["python@3.8"].opt_bin/"python3")

    llvm_bin = Formula["llvm"].opt_bin

    ENV["CC"] = "#{llvm_bin}/clang"
    ENV["CXX"] = "#{llvm_bin}/clang++"

    venv.pip_install "h5py"
    venv.pip_install "pyscf"
    system libexec/"bin/pip3", "install", "-v", buildpath

    pth_contents = "import site; site.addsitedir('#{libexec/site_packages}')\n"
    (prefix/site_packages/"homebrew-hiq-fermion.pth").write pth_contents
  end

  test do
    system Formula["python@3.8"].opt_bin/"python3", "-c", <<~EOS
      from hiqfermion.ops.fermion_operator import FermionOperator
      from hiqfermion.ops.qubit_operator import QubitOperator
      from hiqfermion.utils import (get_fermion_operator, count_qubits,
                                    normal_ordered, hermitian_conjugated,
                                    sz_operator)
    EOS
  end
end
