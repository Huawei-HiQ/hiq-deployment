class HiqCircuit < Formula
  include Language::Python::Virtualenv

  desc "Huawei-HiQ HiQSimulator"
  homepage "https://hiq.huaweicloud.com/en/"
  url "https://files.pythonhosted.org/packages/45/c1/39453dd9e61db6e14cb5116f86788b18ca15c9794593fee46fc258715283/hiq-circuit-0.0.2.tar.gz"
  version "0.0.2"
  sha256 "1c0d28f4ff0f51f3314f047e3a0bf874238c519d1c24153afa45f3e2c6256541"
  license "Apache-2.0"
  revision 0

  depends_on "boost-mpi"
  depends_on "cmake"
  depends_on "glog"
  depends_on "huawei-hiq/hiq-deployment/hiq-projectq"
  depends_on "hwloc"
  depends_on "mpi4py"

  def install
    version = Language::Python.major_minor_version Formula["python@3.8"].opt_bin/"python3"
    site_packages = "lib/python#{version}/site-packages"

    virtualenv_create(libexec, Formula["python@3.8"].opt_bin/"python3")

    llvm_bin = @Formula["llvm"].opt_bin

    ENV["CC"] = "#{llvm_bin}/clang"
    ENV["CXX"] = "#{llvm_bin}/clang++"

    system libexec/"bin/pip3", "install", "-v", buildpath

    pth_contents = "import site; site.addsitedir('#{libexec/site_packages}')\n"
    (prefix/site_packages/"homebrew-hiq-circuit.pth").write pth_contents
  end

  test do
    system "mpirun", "-np", "2", Formula["python@3.8"].opt_bin/"python3", "-c", <<~EOS
      from projectq.ops import H, Measure
      from hiq.projectq.backends import SimulatorMPI
      from hiq.projectq.cengines import GreedyScheduler, HiQMainEngine

      from mpi4py import MPI

      eng = HiQMainEngine(SimulatorMPI(gate_fusion=True, num_local_qubits=4))

      q1 = eng.allocate_qubit()
      H | q1
      Measure | q1
      eng.flush()

      print("Measured: {}".format(int(q1)))
    EOS
  end
end
