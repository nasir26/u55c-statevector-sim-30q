# Known differences between regenerated and submitted outputs

`make reproduce` regenerates every table, macro and figure and compares them with the committed versions, which are
the ones in the submitted manuscript. Everything is identical except the following.

## Analytical power model check (Section on the v07 baseline, response R1.4)

| Macro | Submitted | Regenerated from `results/raw/phase5/v07_energy.json` |
|---|---|---|
| `\NumModelPowerErrMin` / `Max` | 55 / 58 % | 47 / 51 % |
| `\NumModelEnergyErrMin` / `Max` | 358 / 579 % | 338 / 537 % |

Cause: `results/processed/power_model_check.csv` was computed on 2026-10-06 from the first v07 energy run (idle
board power 24.7 W). On 2026-10-07 the v07 energy loops were measured again (idle 26.8 W) and
`results/raw/phase5/v07_energy.json` was replaced; the energy table of the paper uses the new run, but the power
model check was not recomputed. The conclusion (the analytical model overestimates power by about half and energy
several times) holds for both runs.

The committed CSV and macros are kept as submitted. `tests/expected/known_differences.txt` lists the lines the
check allows to differ; any other difference fails `make reproduce`.
