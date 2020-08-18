class HiqProjectq < Formula
  include Language::Python::Virtualenv

  desc "Huawei-HiQ ProjectQ"
  homepage "https://hiq.huaweicloud.com/en/"
  url "https://files.pythonhosted.org/packages/4c/9f/1e7014d3e23fd7ab15e423025af134b723b34b2a33bc2dc726cdc81fcd46/hiq-projectq-0.6.4.post2.tar.gz"
  version "0.6.4"
  sha256 "f404e530cea8a1741062626ca7ebe23e9a3bde1198cd0bf602fde0fe2c9359fe"
  license "Apache-2.0"
  revision 2

  depends_on "llvm"
  depends_on "numpy"
  depends_on "scipy"

  # Fix setup.py
  patch do
    url "http://localhost:8080/brew_cmd_setup_py.patch"
    sha256 "cd900ba7ec9d80c31b752dac533f21a6d10f4ce364efd5a7d343b9a53d0fe91b"
  end

  def install
    version = Language::Python.major_minor_version Formula["python@3.8"].opt_bin/"python3"
    site_packages = "lib/python#{version}/site-packages"

    venv = virtualenv_create(libexec, Formula["python@3.8"].opt_bin/"python3")

    llvm_bin = @Formula["llvm"].opt_bin

    ENV["CC"] = "#{llvm_bin}/clang"
    ENV["CXX"] = "#{llvm_bin}/clang++"

    venv.pip_install "pybind11"
    system libexec/"bin/pip3", "install", "-v", buildpath

    pth_contents = "import site; site.addsitedir('#{libexec/site_packages}')\n"
    (prefix/site_packages/"homebrew-hiq-projectq.pth").write pth_contents
  end

  test do
    system Formula["python@3.8"].opt_bin/"python3", "-c", <<~EOS
      from projectq import MainEngine
      import projectq.cengines
      from projectq.ops import X, H, Rxa
      
      eng = MainEngine()
      qubit = eng.allocate_qubit()
      X | qubit
      H | qubit
      Rx(1.0) | qubit
      eng.flush()
    EOS
  end
end
