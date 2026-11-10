# Changelog

All notable changes to this repository. Versions follow [Semantic Versioning](https://semver.org/).

## [1.0.1] - 2026-11-10

- Fixed: the analytical power model check is recomputed from the committed raw data (power error 47 to 51 %,
  energy error 338 to 537 %; the submitted manuscript has 55 to 58 % and 358 to 579 % from an earlier run). See
  `docs/KNOWN_DIFFERENCES.md`. `make reproduce` now has no allowed differences.

## [1.0.0] - 2026-11-09

First release of the repository, assembled from the revision of the 30 qubit paper (resubmitted to The Journal of
Supercomputing on 2026-10-14).

- HLS engine (`sv_engine`) and exchange (`sv_swap`) kernels, the v07 baseline kernel, the HBM stream benchmark.
- Host instruction set, circuit compiler, NumPy golden model and XRT runtime (one, two and four cards).
- Hardware-free tests: compiler and golden model against Qiskit (2112 cases), runtime on a mocked XRT, C simulation
  of the engine kernel.
- Build configurations, bitstream hashes and post-route reports of every bitstream; bitstreams as release assets.
- Raw FPGA, CPU and GPU measurements, analysis scripts, generated tables and figures, manuscript sources.
- `make setup`, `make test`, `make reproduce`, `make csim`, `make paper`; CI on every push.
- Known difference: four power model macros, see `docs/KNOWN_DIFFERENCES.md`.
