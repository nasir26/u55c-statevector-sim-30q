# Differences between this repository and the submitted manuscript

`make reproduce` regenerates every table, macro and figure and compares them with the committed versions; since
v1.0.1 everything is identical. One set of numbers differs from the submitted manuscript.

## Analytical power model check (Section on the v07 baseline, response R1.4)

| Macro | Submitted manuscript (`paper/manuscript/manuscript.tex`) | This repository (`paper/generated/macros.tex`) |
|---|---|---|
| `\NumModelPowerErrMin` / `Max` | 55 / 58 % | 47 / 51 % |
| `\NumModelEnergyErrMin` / `Max` | 358 / 579 % | 338 / 537 % |

Cause: the submitted values were computed on 2026-10-06 from the first v07 energy run (idle board power 24.7 W).
On 2026-10-07 the v07 energy loops were measured again (idle 26.8 W) and `results/raw/phase5/v07_energy.json` was
replaced; the energy table of the paper uses the new run, but the power model check was not recomputed before
submission. v1.0.1 recomputes it from the committed raw data, so `results/processed/power_model_check.csv` and the
four macros above now follow the same run as the rest of the paper, and a build of `paper/revised/` shows the
corrected values. The submitted single file manuscript in `paper/manuscript/` is kept exactly as submitted. The
conclusion (the analytical model overestimates power by about half and energy several times) holds for both runs.
