#!/bin/bash
# Creates the two Python environments from the recorded specifications, or checks interpreters given instead.
#   envs/fpga : Python 3.8, Qiskit 1.2.4, Qiskit Aer 0.15.1, NumPy 1.24.4 (pyxrt comes from XRT, /opt/xilinx/xrt/python)
#   envs/cpu  : Python 3.11, analysis, figures, CPU baselines (Qiskit Aer 0.17.2, qsim, Qulacs)
# Environment variables: PY_FPGA, PY_CPU (interpreters), MICROMAMBA (binary), ENVS (target directory).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
ENVS=${ENVS:-envs}; MM=${MICROMAMBA:-micromamba}
PY_FPGA=${PY_FPGA:-$ENVS/fpga/bin/python}; PY_CPU=${PY_CPU:-$ENVS/cpu/bin/python}
create() {  # create <name> <interpreter>
  if [ -x "$2" ]; then echo "$1: using $2"; return; fi
  command -v "$MM" >/dev/null || { echo "micromamba not found; install it or set MICROMAMBA, or pass PY_$1"; exit 2; }
  "$MM" create -y -p "$(realpath -m "$ENVS/$1")" -f "setup/env_$1.yml"   # absolute prefix: pip needs it
}
create fpga "$PY_FPGA"; create cpu "$PY_CPU"
"$PY_FPGA" -c "import sys, qiskit, numpy; assert sys.version_info[:2] == (3, 8), sys.version; print('fpga env: python', sys.version.split()[0], 'qiskit', qiskit.__version__, 'numpy', numpy.__version__)"
"$PY_CPU" -c "import sys, numpy, pandas, matplotlib, qiskit; assert sys.version_info[:2] == (3, 11), sys.version; print('cpu env: python', sys.version.split()[0], 'numpy', numpy.__version__, 'pandas', pandas.__version__, 'matplotlib', matplotlib.__version__)"
"$PY_FPGA" -c "import pyxrt" 2>/dev/null && echo "pyxrt: available (hardware runs possible)" || echo "pyxrt: not available (fine for everything except hardware runs)"
