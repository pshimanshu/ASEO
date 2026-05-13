# ASEO — Changes & Implementation Log

Ordered chronologically by development step. Each section covers a distinct phase of work; PRs are noted where merged via GitHub.

---

## Phase 0 — Initial Setup & Restructure

**Goal:** Make the original flat MATLAB source importable and runnable from a clean repo.

- Created `src/`, `scripts/`, `data/`, `docs/` directory layout; moved all source files accordingly and fixed all `addpath` references
- Added `.gitignore` to exclude `results/`, data intermediates, and MATLAB temp files
- Added `README.md` with project structure and algorithm flow overview
- Added `combinFile.m` call in `Main_ASEO.m` to regenerate merged `.mat` files on each run
- Fixed `myboldify1.m` to use `strcmp` instead of `==` for string comparison (MATLAB compatibility)
- Fixed `scriptDir` being cleared by `clear all` — moved assignment to after the clear
- Switched from `TIO` to `LU` monkey and updated `combinFile` filename accordingly

---

## Step 1 — Real-Data Bug Fixes (PR #1)

**Goal:** Get `Main_ASEO.m` running cleanly across all 16 channels, both conditions, with correct plots.

### Numerical / algorithm fixes

| Fix | File | What changed |
|---|---|---|
| `inv()` → backslash operator | `src/function_ASEO.m` | Avoids singular-matrix warnings in weighted LS; numerically stabler |
| Imaginary part warnings | `scripts/Main_ASEO.m` | Wrapped `var()` and AERP plot data in `real()` to suppress spurious imaginary components left over from FFT round-trip |
| Nogo variance baseline | `scripts/Main_ASEO.m` | `var_ori` was using `dataChanGo` even when `go_or_nogo==0`; fixed to use `dataChanNogo` so the variance reduction ratio is compared against the correct condition |
| Negative amplitude axis | `scripts/Main_ASEO.m` | `ylim` used `mean(ampEst)` which can be negative; switched to `max(abs(mean(ampEst)))` so axis limits are always positive |

### Plot fixes

- `drawOnging.m`: added guard against zero/NaN axis range that caused `axis()` crash on channels with no accepted trials
- `Main_ASEO.m`: improved reject-ratio display string in title

### Parameter tuning

- Widened `searchWindowSet` Comp 1 from ±80 ms to **±120 ms** to accommodate the wide latency variability seen in LU data
- Extended `waveformInitSet` for LU channel 5 Comp 1: start window 70→50 ms, end 170→200 ms

### Scope expansion

- Changed `chanSet` from `[5]` to `1:16` — runs all 16 channels in one execution
- Loop already iterated over Go and Nogo conditions; verified both complete correctly
- Output folders `results/LU/Go/` and `results/LU/Nogo/` are auto-created if absent

---

## Step 2 — Quantitative Reporting (PR #2)

**Goal:** Persist the statistics already computed inside the analysis loop rather than discarding them.

### New file: `src/saveRunSummary.m`

A standalone function called once per (channel, condition) pair. Writes one CSV row containing:

- **Trial acceptance rate** (% accepted out of total)
- **Per-component mean ± SD latency shift** (ms), up to 3 components, NaN-padded
- **Per-component mean ± SD amplitude**
- **Latency–RT Pearson r and p-value** — populated for Go only (NaN for Nogo since RT is undefined)
- **Variance reduction ratio** — `var(ASEO residual) / var(AERP residual)`; the paper reports ~0.29–0.30 on monkey LFP
- **AR model order** selected by BIC
- **PSD peak frequency** (Hz) of ongoing activity

The header is written only on the first call (file creation); subsequent calls append. Output paths:

```
results/LU/Go/summary_stats.csv
results/LU/Nogo/summary_stats.csv
```

### Fixes applied during PR review

- Variance ratio: ensured both numerator and denominator use the same set of accepted trials (previously denominator used all trials)
- PSD band: clamped frequency axis to Nyquist (100 Hz) so `psdPeakFreq` is always valid
- RT correlation guard: wrapped `corrcoef` call in a try/catch to avoid crash when fewer than 2 accepted trials remain

---

## Step 3 — Synthetic VSPOA Validation (standalone branch)

**Goal:** Run ASEO on data with a known ground truth to measure latency and amplitude RMSE independently of any real dataset.

### New file: `src/generateSyntheticVSPOA.m`

Implements paper Example 1 (Section V-A-1):

| Parameter | Value |
|---|---|
| Trials (R) | 220 |
| Samples (T) | 120 at 200 Hz |
| ERP components | 2 Gaussian bumps centred at 100 ms and 300 ms |
| Latency jitter | Gaussian(μ=0, σ=10 ms) — independent per component and trial |
| Amplitude | Log-normal (median=1, σ_log=0.5) |
| Ongoing activity | AR(2) resonant at 10 Hz |

The AR pole radius was tuned from the initial `r=0.95` (too narrow; ~3 Hz bandwidth caused the F-step to mistake the noise peak for an ERP component during early iterations) down to **`r=0.70`** (~27 Hz -3 dB bandwidth, realistic for LFP).

Returns ground-truth `latencyTrue` and `ampTrue` so RMSE can be computed against known values.

### New file: `scripts/Run_ASEO_Synthetic.m`

Driver that:

1. Generates synthetic data at a chosen `SingleSNR` (default 10 dB)
2. Initialises ASEO from the AERP (or optionally from ground-truth waveforms via `UseGTInit`)
3. Runs `function_ASEO` and computes latency RMSE (ms) and amplitude RMSE for accepted trials
4. Reports Pearson r between estimated and true values (distinguishes scale/offset bias from noise)
5. Saves three figures to `results/Synthetic/`:
   - `Synth_LatencyScatter_SNR<N>dB.jpg` — estimated vs. true latency (paper Fig 2)
   - `Synth_AmpScatter_SNR<N>dB.jpg` — estimated vs. true amplitude (paper Fig 3)
   - `Synth_VarReduction_SNR<N>dB.jpg` — variance comparison: AERP residual vs. ASEO residual
6. Optional `SweepSNR=true` flag sweeps SNR 0–30 dB and produces RMSE curves (paper Fig 5) plus a `.mat` of numeric results

### MATLAB compatibility fixes (iterative during this phase)

- Replaced `corr()` (Statistics Toolbox) with inline `corrcoef` (base MATLAB)
- Used `reshape()` to force column vectors before `corrcoef` to avoid parser ambiguity
- Fixed chained-parenthesis syntax that MATLAB's parser rejected in one context
- Lowered `thresholdCorr` from 0.6 to **0.5** to avoid over-rejection on synthetic data where noise can momentarily depress trial correlation

---

## Step 4 — Figure 12 Overlay (PR #4)

**Goal:** Reproduce paper Figure 12 — overlay ASEO-estimated component waveforms on the AERP for visual comparison.

### New file: `scripts/Plot_Figure12.m`

Post-processing script (no recomputation) that:

1. Scans `results/LU/{Go,Nogo}/` for saved `*_Go.mat` / `*_Nogo.mat` result files
2. Loads each, extracts `waveformEst`, `ampEst`, `rejectFlag`, `dataAERPGo/Nogo`, `chanNo`
3. Plots on shared axes:
   - Each ASEO component waveform scaled by its mean accepted-trial amplitude, then **normalized to unit peak**
   - Sum of all components (ASEO total), also normalized
   - Original AERP, normalized to unit peak
4. Saves `{dataName}_Figure12_chan<N>.jpg` alongside the existing per-channel results

### Bugs fixed during PR review

| Bug | Fix |
|---|---|
| AERP column index off by one | `dataAERPGo/Nogo` is `[sampNum × chanNum]` indexed by `chanNo`, not by loop counter `kkk` |
| `tVec` offset wrong | Changed from `(1:sampNum)*sampPeri` to `(0:sampNum-1)*sampPeri - preStimulusTime` so time axis is centred at stimulus onset |
| `corr()` → `corrcoef` | Consistency with rest of codebase |
| Empty `acceptIndex` guard | Skip-with-warning instead of crash when all trials are rejected for a channel |
| `var_ori` trial consistency | Use same accepted-trial set for both numerator and denominator of variance ratio |

---

## Files Added / Modified Summary

| File | Status | Step |
|---|---|---|
| `src/function_ASEO.m` | Modified — `inv()` → backslash | 1 |
| `src/drawOnging.m` | Modified — axis crash guard, title typo fix | 1 |
| `scripts/Main_ASEO.m` | Modified — imaginary fixes, Nogo baseline, axis range, chanSet, RT corr, CSV call | 1, 2 |
| `src/saveRunSummary.m` | **New** — per-channel CSV summary function | 2 |
| `src/generateSyntheticVSPOA.m` | **New** — synthetic VSPOA data generator | 3 |
| `scripts/Run_ASEO_Synthetic.m` | **New** — synthetic validation driver | 3 |
| `scripts/Plot_Figure12.m` | **New** — AERP vs. component overlay | 4 |
| `TODO.md` | Updated — steps marked complete | ongoing |
| `README.md` | Updated — new scripts, CSV schema, Fig 12 section | ongoing |
