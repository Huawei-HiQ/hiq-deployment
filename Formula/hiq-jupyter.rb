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

class HiqJupyter < Formula
  include Language::Python::Virtualenv

  desc "Huawei-HiQ Jupyter notebook support"
  homepage "https://hiq.huaweicloud.com/en/"
  url "https://pypi.io/packages/source/h/hiq-jupyter/hiq-jupyter-0.2.2.tar.gz"
  version "0.2.2"
  sha256 "XXXXXXXXX"
  license "MIT"
  revision 2

  depends_on "ipython"
  depends_on "python@3.8"

  def install
    version = Language::Python.major_minor_version Formula["python@3.8"].opt_bin/"python3"
    site_packages = "lib/python#{version}/site-packages"

    venv = virtualenv_create(libexec, Formula["python@3.8"].opt_bin/"python3")

    venv.pip_install "jupyter-react"
    system libexec/"bin/pip3", "install", "-v", buildpath

    pth_contents = "import site; site.addsitedir('#{libexec/site_packages}')\n"
    (prefix/site_packages/"homebrew-hiq-jupyter.pth").write pth_contents
  end

  test do
    system Formula["python@3.8"].opt_bin/"python3", "-c", <<~EOS
      s = 'ok'
    EOS
  end
end
