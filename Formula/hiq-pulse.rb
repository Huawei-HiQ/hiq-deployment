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

class HiqPulse < Formula
  include Language::Python::Virtualenv

  desc "Huawei-HiQ Pulse library and optimal control library"
  homepage "https://hiq.huaweicloud.com/en/"
  url "https://pypi.io/packages/source/h/hiq-pulse/hiq-pulse-1.0.3.tar.gz"
  version "1.0.3"
  sha256 "XXXXXX"
  license "Apache-2.0"
  revision 0

  depends_on "cmake" => :build
  depends_on "huawei/hiq/hiq-projectq"
  depends_on "llvm"
  depends_on "mpi4py"
  depends_on "numpy"
  depends_on "pybind11" => :build
  depends_on "python@3.8"
  depends_on "scipy"

  def install
    version = Language::Python.major_minor_version Formula["python@3.8"].opt_bin/"python3"
    site_packages = "lib/python#{version}/site-packages"

    virtualenv_create(libexec, Formula["python@3.8"].opt_bin/"python3")

    llvm_bin = Formula["llvm"].opt_bin

    ENV["CC"] = "#{llvm_bin}/clang"
    ENV["CXX"] = "#{llvm_bin}/clang++"

    venv.pip_install "matplotlib"
    system libexec/"bin/pip3", "install", "-v", buildpath

    pth_contents = "import site; site.addsitedir('#{libexec/site_packages}')\n"
    (prefix/site_packages/"homebrew-hiq-pulse.pth").write pth_contents
  end

  test do
    system "mpirun", "-np", "2", Formula["python@3.8"].opt_bin/"python3", "-c", "#{libexec/site_packages}/hiqpulse/examples/GRAPE/mpi_example.py"
  end
end
