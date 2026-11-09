# Environment for the measurement host. Source it from the repository root:  source env.sh
# Paths of the Xilinx tools can be overridden before sourcing (defaults are the standard install locations):
#   XRT_SETUP       XRT setup script            (default /opt/xilinx/xrt/setup.sh)
#   VITIS_SETTINGS  Vitis 2023.2 settings script (default /tools/Xilinx/Vitis/2023.2/settings64.sh)
export WS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XRT_SETUP=${XRT_SETUP:-/opt/xilinx/xrt/setup.sh}
VITIS_SETTINGS=${VITIS_SETTINGS:-/tools/Xilinx/Vitis/2023.2/settings64.sh}
export TMPDIR=$WS/tmp; mkdir -p "$TMPDIR"
export XDG_CACHE_HOME=$WS/cache
export MPLCONFIGDIR=$WS/cache/matplotlib
export PYTHONNOUSERSITE=1          # keeps ~/.local site-packages out of the environments
export PYTHONDONTWRITEBYTECODE=1
export XILINX_LOCAL_USER_DATA=no   # stops the Vitis tools writing into ~/.Xilinx
[ -f "$XRT_SETUP" ] && source "$XRT_SETUP" >/dev/null 2>&1
[ -n "${XILINX_XRT:-}" ] && export PYTHONPATH=$XILINX_XRT/python${PYTHONPATH:+:$PYTHONPATH}
vitis_env() { source "$VITIS_SETTINGS"; }
export PATH=$WS/envs/fpga/bin:$WS/envs/cpu/bin:$PATH
