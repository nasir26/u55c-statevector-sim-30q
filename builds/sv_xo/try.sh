#!/bin/bash
# usage: try.sh <tag> <pre.tcl lines...>  -> prints Total row of csynth estimate
source <WS>/env.sh; vitis_env
T=$WS/builds/sv_xo/try_$1; shift; mkdir -p $T; cd $T; printf '%s\n' "$@" > pre.tcl
v++ -c -t hw --platform xilinx_u55c_gen3x16_xdma_3_202210_1 -k sv_engine --hls.clock 300000000:sv_engine \
  --hls.pre_tcl $T/pre.tcl --temp_dir $T/_x --report_dir $T/reports --log_dir $T/logs -o $T/sv_engine.xo $WS/kernels/sv/sv_engine.cpp > $T/log 2>&1
/bin/grep -m1 -E '^\|Total' $T/reports/sv_engine/hls_reports/sv_engine_csynth.rpt; /bin/grep -hE 'Estimated Fmax|Final II = [2-9]' $T/logs/sv_engine/sv_engine_vitis_hls.log | cut -c1-120
