# u55c-statevector-sim-30q

[![ci](https://github.com/nasir26/u55c-statevector-sim-30q/actions/workflows/ci.yml/badge.svg)](https://github.com/nasir26/u55c-statevector-sim-30q/actions/workflows/ci.yml)

A statevector quantum circuit simulator for the AMD Alveo U55C FPGA card (16 GB HBM2), up to 30 qubits on one card
in single precision, together with the CPU and GPU baselines, every raw measurement, and the scripts that turn the
measurements into the tables and figures of the paper.

## Why it exists

Statevector simulation is limited by memory bandwidth, and data centre FPGAs with HBM offer bandwidth close to that
of workstation GPUs. This repository is the complete artifact of the study "FPGA Based Quantum Circuit Simulator:
Processing 30 Qubit Systems": it shows how far one U55C gets, where it beats a 128 core server and an NVIDIA A100,
and where it does not, with every number traceable to a raw record.

## Architecture

```
 Qiskit circuit
      |  host/sv/compiler.py: every gate becomes one MUX2 record (a 2x2 complex matrix on amplitude pairs,
      |  optionally controlled); gates are scheduled into passes that share one sweep over HBM
      v
 instruction stream  ----------------------------->  host/sv/model.py (NumPy golden model, used by the tests)
      |  host/sv/runtime.py (XRT)
      v
 Alveo U55C:  sv_engine x16  (one streaming engine per HBM pseudo-channel, on-chip tiles of the state)
              sv_swap        (device-side exchange kernel for qubit remaps between channels)
```

Details: `docs/ARCHITECTURE.md` (design), `docs/CODE_MAP.md` (files), `docs/BASELINE_AUDIT.md` (the earlier v07
kernel this work replaces), `docs/PROVENANCE.md` (where each part came from).

## Layout

| Path | Contents |
|---|---|
| `kernels/sv/` | HLS sources of the engine (`sv_engine.cpp`) and exchange (`sv_swap.cpp`) kernels, C testbench `tb.cpp` |
| `kernels/hbm_stream/` | HBM streaming microbenchmark kernel |
| `kernels/v07/`, `host/v07/` | the earlier v07 kernel and host, kept unchanged as the measured baseline |
| `host/sv/` | instruction set, compiler, golden model, XRT runtime (one, two and four cards) |
| `tests/` | compiler and model tests, mocked runtime, C simulation, hardware functional suite |
| `builds/<name>/` | link configuration, bitstream hash and metadata, post-route utilisation and timing reports |
| `bench/` | FPGA, CPU and GPU benchmark drivers and campaign scripts |
| `circuits/` | benchmark circuit generators (fixed seeds) and exported OpenQASM |
| `results/raw/` | every raw measurement (JSON/JSONL, power CSV, logs); `results/raw/env/` the captured versions |
| `results/processed/` | tables derived from the raw data |
| `analysis/` | loaders, table and figure generators |
| `paper/generated/` | every number and table of the paper as LaTeX, generated from `results/raw/` |
| `paper/revised/` | manuscript sources, built from `paper/generated/` and the generated figures |
| `paper/manuscript/` | the submitted single file manuscript source and its figures |
| `logs/` | build logs read by the table generator, functional suite and campaign logs, host inventory |
| `setup/` | exact environment specifications (`env_fpga.yml`, `env_cpu.yml`) and `setup.sh` |
| `scripts/` | bitstream download, reproduction check, lint, paper build, environment capture |
| `docs/` | architecture, code map, baseline audit, provenance, differences from the submitted manuscript |

## Quick start (no FPGA needed)

```
git clone https://github.com/nasir26/u55c-statevector-sim-30q.git
cd u55c-statevector-sim-30q
make setup        # creates envs/fpga and envs/cpu with micromamba from setup/env_*.yml
make test         # compiler and golden model against Qiskit (2112 cases), runtime on a mocked XRT (about 1 minute)
make reproduce    # regenerates every table, macro and figure from results/raw/ and checks them (about 15 seconds)
```

If you already have suitable interpreters, pass them instead of creating environments:
`make setup test reproduce PY_FPGA=/path/to/python3.8 PY_CPU=/path/to/python3.11`. A container with both
environments: `docker build -t sv30q . && docker run --rm sv30q` (also usable as a devcontainer).

`make help` lists every target.

## Reproduction

### Without hardware

| Step | Command | What it checks |
|---|---|---|
| Unit tests | `make test` | the compiler and golden model agree with `qiskit.quantum_info.Statevector` on 2112 circuit, tiling and fusion cases (infidelity below 1e-5); the runtime runs one, two and four virtual cards on a mocked XRT |
| C simulation | `make csim` (needs the Vitis HLS 2023.2 headers, set `XILINX_HLS`) | the HLS engine source, compiled with g++, agrees with the golden model segment by segment (35 circuits, n = 7 to 14) |
| Tables and figures | `make reproduce` | regenerates `results/processed/`, `paper/generated/` and the eight figures, then compares them with the committed (submitted) versions; figures are compared by content, ignoring creation dates |
| Manuscript | `make paper` (needs latexmk and pdflatex) | builds `build/paper/main.pdf` from the regenerated numbers and figures |

Every regenerated output matches the committed one, and `make reproduce` fails on any difference. Four macros of the
analytical power model check differ from the submitted manuscript because they were recomputed from the committed raw
data (`docs/KNOWN_DIFFERENCES.md`).

### With hardware

| Step | Command |
|---|---|
| Bitstreams | `make bitstreams` (downloads the nine bitstreams of the release `bitstreams-v1` and checks their SHA-256) |
| Functional suite | `make hw-suite BDF=<PCIe address> XCLBIN=builds/sv_e16w512/sv.xclbin` (the 398 case suite of the paper ran on `sv_e16w512`) |
| FPGA campaigns | `source env.sh; FLAG=sv_e16w_m4 bench/fpga/campaign.sh <BDF> main\|ablate\|energy\|builds\|jitter\|suite` |
| Largest widths | `PARK=<bitstream> BDF=<BDF> bench/fpga/run_maxwidth.sh` (n = 24 to 30, checked against CPU references) |
| CPU baselines | `bench/cpu/campaign.sh; bench/cpu/campaign_extra.sh` (host otherwise idle) |
| GPU baselines | `bench/gpu/campaign_a100.sh` (batch scheduler, see the script header) or `bench/gpu/run_local_gpu.sh <tag>` |
| Rebuild a bitstream | see "Rebuilding the bitstreams" below |

FPGA runs pace themselves thermally: each repetition starts below 80 C and a run aborts at 90 C (FPGA) or 85 C
(HBM). New raw records land in `results/raw/`; `make reproduce` then regenerates everything from them.

### Rebuilding the bitstreams

A rebuild gives a functionally equal design, not a bit identical file (placement and routing depend on the run).

```
source env.sh; vitis_env
v++ -c -t hw --platform xilinx_u55c_gen3x16_xdma_3_202210_1 -k sv_engine --hls.clock 300000000:sv_engine -o sv_engine.xo kernels/sv/sv_engine.cpp
v++ -c -t hw --platform xilinx_u55c_gen3x16_xdma_3_202210_1 -k sv_swap   --hls.clock 300000000:sv_swap   -o sv_swap.xo   kernels/sv/sv_swap.cpp
v++ -l -t hw --platform xilinx_u55c_gen3x16_xdma_3_202210_1 --config builds/<name>/link.cfg --kernel_frequency 300 -o sv.xclbin sv_engine.xo sv_swap.xo
```

`builds/link_sv.sh <name> <engines> [pc_stride] [swap_CUs] [pcs_per_engine]` writes a `link.cfg` and links. Add
`-D SV_WIDE` to the engine compile for the 512-bit variant. Each link takes 2 to 8 hours.

| Build | Engines | Notes |
|---|---|---|
| `sv_e16w_m4` | 16 | main build: 256-bit ports, up to 4 high qubits per pass |
| `sv_e16w512` | 16 | 512-bit ports |
| `sv_e16w`, `sv_e16` | 16 | 256-bit ports, 2 high qubits per pass |
| `sv_e8` | 8 | 8 engine variant |
| `sv_e8_v1_flatbug` | 8 | superseded build behind the superseded records (kept for traceability) |
| `hbm1_c16w512`, `hbm1_c32w256` | 16, 32 | HBM bandwidth microbenchmarks |

## Requirements and versions

| What | Version used for the paper |
|---|---|
| FPGA card | AMD Alveo U55C, shell `xilinx_u55c_gen3x16_xdma_base_3`, platform `xilinx_u55c_gen3x16_xdma_3_202210_1` |
| XRT | 2.16.204 (2023.2) |
| Vitis / Vivado / Vitis HLS | 2023.2 (only to rebuild bitstreams and for `make csim`) |
| Host | 2 x 64 core x86-64, Ubuntu 20.04, kernel 5.15, gcc 9.4.0 |
| Python, FPGA host and tests | 3.8.20, Qiskit 1.2.4, Qiskit Aer 0.15.1, NumPy 1.24.4 (`setup/env_fpga.yml`) |
| Python, analysis and CPU baselines | 3.11.16, Qiskit 2.5.2, Qiskit Aer 0.17.2, qsimcirq 0.22.1, Qulacs 0.6.14, NumPy 2.4.6, pandas 3.0.6, matplotlib 3.11.2 (`setup/env_cpu.yml`) |
| GPU baselines | NVIDIA A100 SXM4 80 GB, driver 615.71.09, CUDA 12, CUDA-Q 0.12.0, cuQuantum 26.9.0, Qiskit Aer GPU 0.15.1 |
| Manuscript | TeX Live with latexmk, Springer Nature `sn-jnl` class (included) |

Captured versions of every run: `results/raw/env/`.

## Results summary

| Result | Value |
|---|---|
| Largest circuit on one card | 30 qubits, complex64 (8 GiB state), verified against a complex128 Qiskit Aer statevector (worst infidelity 3.7e-13) |
| HBM copy bandwidth | 399 GB/s over 32 pseudo-channels, 12.8 GB/s read per channel |
| Functional suite | 398 of 398 cases pass (infidelity at most 1e-5) |
| Against the earlier v07 HBM kernel | end-to-end time 72 to 836 x lower at 24 qubits; energy per circuit 13 to 121 x lower |
| Against a 128 core CPU server (best of Aer, qsim, Qulacs) | the card is faster for bandwidth-bound circuits from 26 qubits (GHZ-30 in 4.1 s, 1.21 x faster); for QFT, random circuits and VQE the server needs 0.75 to 0.84 of the FPGA time at 30 qubits |
| Against an NVIDIA A100 | the A100 is 2.86 x (random circuits) to 3.36 x (QFT) faster at 30 qubits, about as fast for GHZ, and holds up to 33 qubits |
| Card power while simulating | 39 to 52 W |

## Figures and tables of the paper

| Paper item | Produced by | Output |
|---|---|---|
| Fig. architecture (`fig:arch`) | `analysis/fig_architecture.py` (PY_FPGA) | `fig_architecture.pdf` |
| Fig. roofline (`fig:roofline`) | `analysis/make_figures.py roofline` | `fig_roofline.pdf` |
| Fig. maximum width (`fig:maxwidth`) | `analysis/make_figures.py maxwidth` | `fig_maxwidth.pdf` |
| Fig. builds (`fig:builds`) | `analysis/make_figures.py builds` | `fig_builds.pdf` |
| Fig. CU scaling (`fig:cu`) | `analysis/make_figures.py cu` | `fig_cu_scaling.pdf` |
| Fig. time breakdown (`fig:breakdown`) | `analysis/make_figures.py breakdown` | `fig_breakdown.pdf` |
| Fig. cross-platform (`fig:xplat`) | `analysis/make_figures.py xplat` | `fig_xplat.pdf` |
| Fig. jitter (`fig:jitter`) | `analysis/make_figures.py jitter` | `fig_jitter.pdf` |
| Table timing definitions (`tab:timing`) | `analysis/make_tables.py` (`timing_defs`) | `paper/generated/tab_timing_defs.tex` |
| Table hardware and software (`tab:hwconfig`) | `analysis/make_tables.py` (`hwconfig`) | `paper/generated/tab_hwconfig.tex` |
| Table v07 audit (`tab:v07`) | `analysis/v07_baseline_summary.py`, `analysis/make_tables.py` (`v07_macros`) | `results/processed/v07_baseline.csv`, macros |
| Table builds (`tab:builds`) | `analysis/make_tables.py` (`builds`) | `paper/generated/tab_builds.tex` |
| Table HBM bandwidth (`tab:hbm`) | `analysis/make_tables.py` (`hbm`) | `paper/generated/tab_hbm.tex` |
| Table gate support (`tab:gates`) | `analysis/make_tables.py` (`gate_support`) | `paper/generated/tab_gate_support.tex` |
| Table functional suite (`tab:suite`) | `analysis/make_tables.py` (`suite`) | `paper/generated/tab_suite.tex` |
| Table maximum width (`tab:maxwidth`) | `analysis/make_tables.py` (`maxwidth`) | `paper/generated/tab_maxwidth.tex` |
| Table ablations (`tab:ablation`) | `analysis/make_tables.py` (`ablations`) | `paper/generated/tab_ablation.tex` |
| Table cross-platform (`tab:xplat`) | `analysis/make_tables.py` (`xplat`) | `paper/generated/tab_xplat.tex` |
| Table energy (`tab:energy`) | `analysis/make_tables.py` (`energy`) | `paper/generated/tab_energy.tex` |
| Every number in the text | `analysis/make_tables.py` | `paper/generated/macros.tex` |
| Power model check (response R1.4) | `analysis/power_model_check.py` | `results/processed/power_model_check.csv` |

No number in the manuscript is typed by hand. `make reproduce` runs all of the above in the right order.

Host names in raw logs and reports are replaced by placeholders (`fpga-host`, `gpu-node`, and `<WS>` for the
workspace path). Author e-mail addresses are removed from the manuscript sources in this repository.

## Citation

Cite the paper (also in `CITATION.cff`):

A. Tiwari, N. Ali, N. Khan, I. Mazhar, K. Islur, H. Gupta, S. Kumar, P. Tyagi, R. Kumar Neiwal, "FPGA Based
Quantum Circuit Simulator: Processing 30 Qubit Systems", Research Square preprint (2026),
doi:[10.21203/rs.3.rs-8581344/v1](https://doi.org/10.21203/rs.3.rs-8581344/v1); revision under review at The
Journal of Supercomputing.

## License

Not yet licensed: see `LICENSE_PENDING.md`. Third-party material: `THIRD_PARTY_LICENSES.md`.

## Author

Nasir Ali, Centre for Development of Advanced Computing (C-DAC), Noida, India.
