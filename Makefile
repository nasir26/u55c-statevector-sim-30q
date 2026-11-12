# One-command entry points. Everything here runs without an FPGA card; the hardware steps are listed by
# `make help` and documented in README.md.
#
# Two Python environments are used (exact versions in setup/env_fpga.yml and setup/env_cpu.yml):
#   PY_FPGA  Python 3.8, Qiskit 1.2.4, NumPy 1.24 : host compiler, golden model, runtime, tests, architecture figure
#   PY_CPU   Python 3.11, NumPy 2.4, pandas 3.0, matplotlib 3.11 : analysis, tables, figures
# `make setup` creates both under envs/ with micromamba. To use interpreters you already have, pass them:
#   make setup test reproduce PY_FPGA=/path/to/python3.8 PY_CPU=/path/to/python3.11

SHELL      := /bin/bash
ENVS       ?= envs
PY_FPGA    ?= $(ENVS)/fpga/bin/python
PY_CPU     ?= $(ENVS)/cpu/bin/python
MICROMAMBA ?= micromamba
BUILD      ?= build
BDF        ?=
XCLBIN     ?= builds/sv_e16w_m4/sv.xclbin
XILINX_HLS ?= /tools/Xilinx/Vitis_HLS/2023.2
CXX        ?= g++

export PYTHONDONTWRITEBYTECODE := 1
export PYTHONNOUSERSITE        := 1
export MPLCONFIGDIR            ?= $(CURDIR)/$(BUILD)/mplconfig
export FIG_OUT                 := $(CURDIR)/$(BUILD)/figures

.PHONY: help setup lint test reproduce tables figures check paper paper-submitted csim bitstreams hw-suite clean

help:
	@echo "Hardware free:"
	@echo "  make setup       create envs/fpga and envs/cpu (micromamba), or check PY_FPGA / PY_CPU if given"
	@echo "  make lint        syntax checks of all Python and shell sources (ruff as well, if installed)"
	@echo "  make test        compiler and golden model vs Qiskit (2112 cases), runtime on a mocked XRT"
	@echo "  make reproduce   regenerate every table, macro and figure from results/raw and compare with the committed ones"
	@echo "  make paper       build the manuscript PDF from the regenerated numbers (needs latexmk)"
	@echo "  make paper-submitted  build the manuscript exactly as submitted (paper/manuscript/)"
	@echo "Needs Vitis 2023.2 / an Alveo U55C:"
	@echo "  make csim        C simulation of the engine kernel against the golden model (g++ with the Vitis HLS headers)"
	@echo "  make bitstreams  download the release bitstreams and check their SHA-256"
	@echo "  make hw-suite BDF=<pcie address>   functional suite on a card"

setup:
	PY_FPGA="$(PY_FPGA)" PY_CPU="$(PY_CPU)" MICROMAMBA="$(MICROMAMBA)" ENVS="$(ENVS)" setup/setup.sh

lint:
	scripts/lint.sh "$(PY_CPU)"

test:
	$(PY_FPGA) tests/test_compiler_model.py
	$(PY_FPGA) tests/test_runtime_mock.py

reproduce: tables figures check

tables:
	$(PY_CPU) analysis/power_model_check.py
	$(PY_CPU) analysis/v07_baseline_summary.py
	$(PY_CPU) analysis/make_tables.py

figures:
	mkdir -p $(FIG_OUT) $(MPLCONFIGDIR)
	$(PY_CPU) analysis/make_figures.py
	$(PY_FPGA) analysis/fig_architecture.py

check:
	scripts/check_reproduction.sh "$(PY_CPU)" "$(FIG_OUT)"

paper: tables figures
	scripts/build_paper.sh "$(FIG_OUT)" "$(BUILD)/paper"

# the manuscript as submitted (paper/manuscript/, self-contained); not regenerated from the data
paper-submitted:
	mkdir -p build/paper-submitted
	cd paper/manuscript && latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=../../build/paper-submitted manuscript.tex
	@echo "manuscript as submitted: build/paper-submitted/manuscript.pdf"

$(BUILD)/sv_tb: kernels/sv/sv_engine.cpp kernels/sv/tb.cpp
	@test -f $(XILINX_HLS)/include/ap_int.h || { echo "set XILINX_HLS to a Vitis HLS install (needs include/ap_int.h)"; exit 2; }
	mkdir -p $(BUILD)
	$(CXX) -O2 -std=c++14 -I$(XILINX_HLS)/include $^ -o $@

csim: $(BUILD)/sv_tb
	SV_TB=$(CURDIR)/$(BUILD)/sv_tb CSIM_DIR=$(CURDIR)/$(BUILD)/csim $(PY_FPGA) tests/test_sv_csim.py

bitstreams:
	scripts/fetch_bitstreams.sh

hw-suite:
	@test -n "$(BDF)" || { echo "set BDF to the card's PCIe address (xbutil examine)"; exit 2; }
	$(PY_FPGA) tests/run_suite_sv.py $(BDF) $(XCLBIN) 16 4 $(BUILD)/suite.json 24,26,28,30

clean:
	rm -rf $(BUILD)
