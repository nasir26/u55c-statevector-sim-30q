# Audit of the 31 references in the submitted manuscript (R4.m1)

Method: every `\bibitem` was queried against Crossref (`scripts/refcheck.py`, raw top-3 matches in `paper/refcheck/*.json`,
2026-10-07); arXiv-only items were checked on arxiv.org; vendor documents on docs.amd.com / GitHub. Decision column:
**keep** (metadata correct), **fix** (real work, metadata corrected as shown), **remove** (no evidence the work exists).

| Key (submitted) | Verdict | Verified record | Correction needed |
|---|---|---|---|
| preskill2018quantum | keep | Quantum 2, 79 (2018), doi:10.22331/q-2018-08-06-79 | add DOI |
| arute2019quantum | keep | Nature 574, 505-510 (2019), doi:10.1038/s41586-019-1666-5 | add DOI |
| pednault2017breaking | fix | arXiv:1710.05867 (2017); current arXiv title "Pareto-Efficient Quantum Circuit Simulation Using Tensor Contraction Deferral", 9 authors (Pednault, Gunnels, Nannicini, Horesh, Magerlein, Solomonik, Draeger, Holland, Wisnieff) | cite v1 title explicitly as "arXiv:1710.05867v1" or use current metadata; author list incomplete |
| villalonga2019flexible | keep | npj Quantum Inf. 5, 86 (2019), doi:10.1038/s41534-019-0196-1 | add DOI |
| jones2012quest | fix | Sci. Rep. 9, 10736 (2019), doi:10.1038/s41598-019-47174-9 | key year 2012 -> 2019 (entry text already 2019) |
| suzuki2021qulacs | keep | Quantum 5, 559 (2021), doi:10.22331/q-2021-10-06-559 | add DOI |
| khalid2016fpga | fix | ICCD 2004, pp. 310-315, doi:10.1109/iccd.2004.1347938 | key year 2016 -> 2004 |
| silva2017quantum | fix | Lee, Y.H., Khalil-Hani, M., Marsono, M.N.: "An FPGA-Based Quantum Computing Emulation Framework Based on Serial-Parallel Architecture", Int. J. Reconfigurable Computing 2016, 5718124, doi:10.1155/2016/5718124 | **wrong authors and venue** in the submission ("Silva, J.A., Pereira, M.A., ISRC 2017"); text mentions "Silva and Pereira ... sixteen qubits" must be rewritten |
| aminian2008fpga | keep | ISVLSI 2008, doi:10.1109/isvlsi.2008.43 | add DOI |
| mahmud2020fpga | fix | Quantum Engineering 1(2), e19 (2019), doi:10.1002/que2.19 | volume/issue/article/year ("2(2), e38 (2020)" in submission) |
| pilch2019fpga | keep | J. Comput. Electron. 18, 329-342 (2019), doi:10.1007/s10825-018-1287-5 | add DOI |
| xilinx2023alveo | keep | DS978 rev 1.3 (2023-06-23), https://docs.amd.com/r/en-US/ds978-u55c | URL |
| vitis2023hls | fix | UG1399 (2023.2), https://docs.amd.com/r/2023.2-English/ug1399-vitis-hls | version 2023.1 -> 2023.2 (toolchain actually used) |
| xrt2023 | keep | https://xilinx.github.io/XRT/ | -- |
| nvidia2024cudaq | keep | https://nvidia.github.io/cuda-quantum/ | -- |
| qiskit2021 | fix | arXiv:2405.08810 (2024) "Quantum computing with Qiskit" | key year 2021 -> 2024 |
| nielsen2010quantum | keep | Cambridge Univ. Press, 10th anniv. ed. (2010), doi:10.1017/CBO9780511976667 | -- |
| shor1997polynomial | keep | SIAM Rev. 41(2), 303-332 (1999), doi:10.1137/S0036144598347011 | key year cosmetic |
| grover1996fast | keep | STOC '96, pp. 212-219, doi:10.1145/237814.237866 | -- |
| boixo2018characterizing | keep | Nat. Phys. 14, 595-600 (2018), doi:10.1038/s41567-018-0124-x | -- |
| peruzzo2014variational | keep | Nat. Commun. 5, 4213 (2014), doi:10.1038/ncomms5213 | -- |
| farhi2014quantum | keep | arXiv:1411.4028 (2014) | -- |
| markov2018quantum | fix | SIAM J. Comput. 38(3), 963-981 (2008), doi:10.1137/050644756 | key year 2018 -> 2008 |
| vidal2003efficient | keep | PRL 91, 147902 (2003), doi:10.1103/PhysRevLett.91.147902 | -- |
| gottesman1998heisenberg | keep | arXiv:quant-ph/9807006 (Group22 proceedings, 1999) | -- |
| aaronson2004improved | keep | PRA 70, 052328 (2004), doi:10.1103/PhysRevA.70.052328 | -- |
| zhang2020fpga | **remove** | no record: Crossref top matches unrelated (doi:10.1109/tcad.2020.3013047 is a CPU/GPU data-initialisation paper); web search finds nothing | delete; rewrite the sentence on hybrid GPU-FPGA designs or cite a verified hybrid work (e.g. suzuki2023hybrid, CPU-FPGA) |
| li2020distributed | **remove** | no record in Crossref or web search for an FPT 2020 paper of that title/authors | delete; multi-FPGA prior work to be cited only from verified sources |
| chen2018quantum | keep | Sci. Bull. 63(15), 964-971 (2018), doi:10.1016/j.scib.2018.06.007 | -- |
| cross2018ibm | fix | arXiv:1707.03429 (2017), "Open Quantum Assembly Language" | key cosmetic |
| hbm2016 | keep | JEDEC JESD235A (2016) | -- |

Summary: 31 entries -> 29 real (19 keep as is, 10 with corrected metadata), **2 removed as unverifiable**
(zhang2020fpga, li2020distributed). One real paper was cited with the wrong authors (silva2017quantum).

Note for the authors: a 2026 Research Square preprint, "Multi-FPGA Quantum Circuit Simulation: A Distributed
Statevector Architecture" (rs-10128153, https://www.researchsquare.com/article/rs-10128153), describes a 4 x U55C,
8-bank, double-precision interleaved design very close to the v07 kernel. If it is from the same group it must be
disclosed/cited (overlap); it is NOT cited by me without author confirmation.
