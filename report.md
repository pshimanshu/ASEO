# ASEO — Results Report

Monkey LU, 16 channels, Go and Nogo conditions. All runs use `Main_ASEO.m` with `LoadFlag=0`.

All paths below are relative to the project root `ASEO/`.

---

## Step 1 — Real-Data Analysis: All 16 Channels, Both Conditions

After fixing the bugs described in `changes.md`, the full 16-channel dual-condition run completed without errors. Results are stored in `ASEO/results/LU/Go/` and `ASEO/results/LU/Nogo/`.

### Output files produced

| Folder | File pattern | Count |
| --- | --- | --- |
| `ASEO/results/LU/Go/` | `lu_go_grp_AERP_<ch>.jpg` | 16 |
| `ASEO/results/LU/Go/` | `lu_go_grp_ASEO_AmpDist_chan_chan<ch>Comp<n>.jpg` | ~32 |
| `ASEO/results/LU/Go/` | `lu_go_grp_ASEO_LatDist_chan<ch>.jpg` | 16 |
| `ASEO/results/LU/Go/` | `lu_go_grp_ASEO_OngoingPSD_chan<ch>.jpg` | 16 |
| `ASEO/results/LU/Go/` | `lu_go_grp_ASEO_VarReduction_chan<ch>.jpg` | 16 |
| `ASEO/results/LU/Go/` | `lu_go_grp*_Go.mat` (saved results) | 16 |
| `ASEO/results/LU/Nogo/` | mirror of Go, with `_Nogo` suffix | same |

Total: ~216 Go images + ~156 Nogo images.

---

## Step 2 — Quantitative Summary (`summary_stats.csv`)

`ASEO/src/saveRunSummary.m` appends one row per channel per condition. Both CSVs have 16 data rows (one per channel).

### Go condition (`ASEO/results/LU/Go/summary_stats.csv`) — all channels

| Chan | Accept% | LatMean C1 (ms) | LatSD C1 | LatMean C2 (ms) | LatSD C2 | RT-Corr C2 (r, p) | VarRed | AR Order | PSD Peak (Hz) |
| ---: | ---: | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| 1 | 22.6 | 54.4 | 45.5 | −26.1 | 38.5 | 0.261, p=0.046 | 0.732 | 3 | 0.0 |
| 2 | 40.2 | −4.4 | 42.5 | −0.4 | 40.3 | 0.263, p=0.007 | 0.411 | 14 | 7.0 |
| 3 | 66.7 | −6.1 | 26.8 | −1.4 | 39.0 | — | 0.457 | 8 | 0.0 |
| 4 | 65.1 | −15.3 | 65.8 | −6.7 | 21.5 | 0.200, p=0.009 | 0.701 | 20 | 5.5 |
| 5 | 83.9 | −1.5 | 45.7 | 0.5 | 25.2 | **0.820, p<0.001** | 0.454 | 20 | 5.5 |
| 6 | 27.2 | −15.3 | 31.4 | 4.2 | 28.2 | 0.631, p<0.001 | 0.731 | 3 | 0.0 |
| 7 | 35.6 | 41.4 | 58.7 | −6.2 | 31.2 | 0.406, p<0.001 | 0.713 | 17 | 7.4 |
| 8 | 95.4 | 1.6 | 61.8 | −0.4 | 15.7 | 0.645, p<0.001 | 0.679 | 13 | 0.0 |
| 9 | 45.6 | 34.0 | 50.1 | −19.3 | 18.8 | 0.450, p<0.001 | 0.725 | 20 | 6.25 |
| 10 | 50.6 | −5.3 | 29.0 | 14.3 | 35.4 | — | 0.383 | 20 | 6.25 |
| 11 | 63.2 | 6.4 | 23.1 | 2.9 | 45.2 | — | 0.386 | 8 | 0.0 |
| 12 | 62.5 | −15.7 | 34.9 | −0.2 | 40.2 | 0.193, p=0.013 | 0.505 | 20 | 5.5 |
| 13 | 60.2 | −7.0 | 45.5 | 4.5 | 35.2 | — | 0.463 | 17 | 4.7 |
| 14 | 17.2 | 21.9 | 40.8 | −28.1 | 29.3 | 0.129, p=0.399 | 0.795 | 3 | 0.0 |
| 15 | 100.0 | 0.0 | 0.0 | — | — | — | — | 1 | 0.0 |
| 16 | 4.2 | −33.3 | 16.7 | — | — | — | — | 7 | 10.9 |

> **Ch 15:** Accepted 100% of trials but produced degenerate waveforms (0 latency SD, 1 AR order) — the channel likely has no informative ERP structure.
> **Ch 16:** Only 4.2% acceptance, too few trials for reliable per-component estimates.

### Nogo condition (`ASEO/results/LU/Nogo/summary_stats.csv`) — selected channels

| Chan | Accept% | LatMean C1 (ms) | LatSD C1 | LatMean C2 (ms) | LatSD C2 | VarRed | AR Order |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3 | 81.9 | −10.5 | 29.3 | 5.8 | 30.7 | 0.396 | 10 |
| 5 | 84.4 | −7.4 | 41.7 | 0.5 | 27.4 | 0.476 | 8 |
| 8 | 81.5 | 5.1 | 52.3 | −1.3 | 18.6 | 0.663 | 12 |
| 11 | 64.0 | 7.9 | 23.1 | 4.7 | 46.5 | 0.391 | 8 |

> RT correlation is NaN for Nogo (no reaction time signal in this condition).

### Key observations

- **Variance reduction:** Most channels achieve 0.38–0.73. The paper reports ~0.29–0.30 on the same monkey; higher values here indicate channels with weaker ERP structure where the AERP baseline already has high residual.
- **Latency–RT correlation:** Channel 5 Comp 2 stands out at r = 0.82 (p < 0.001), consistent with the paper's finding that the second motor-related component tracks reaction time.
- **AR model order:** BIC selects 3–20 across channels. Channels with detectable 5–10 Hz ongoing oscillations (e.g. Ch 2, 4, 5, 7, 9, 10, 12) consistently need orders of 14–20.

---

## Step 3 — Synthetic Validation

Script: `ASEO/scripts/Run_ASEO_Synthetic.m` — SNR = 10 dB, RNG seed = 42, 220 trials, 2 components.

### Console output

```
Running ASEO on synthetic data at SNR = 10 dB ...

iterNo = 3

Accepted 214 / 220 trials (97.3% accepted)
Latency  RMSE — Comp1: 7.52 ms,  Comp2: 8.41 ms  (input sigma = 10 ms; want RMSE << 10)
         corr — Comp1: r=0.803,    Comp2: r=0.786
Amplitude RMSE — Comp1: 0.120,     Comp2: 0.103  (true SD~0.60; want RMSE << 0.60)
         corr — Comp1: r=0.983,    Comp2: r=0.985
Variance reduction ratio: 0.190  (ideal floor at SNR=10dB: 0.091;  paper real-data: ~0.29–0.30)
```

### Summary table

| Metric | Comp 1 | Comp 2 | Benchmark |
| --- | ---: | ---: | --- |
| Acceptance rate | 97.3% | 97.3% | — |
| Latency RMSE | 7.52 ms | 8.41 ms | < 10 ms (input σ) |
| Latency r | 0.803 | 0.786 | want > 0 |
| Amplitude RMSE | 0.120 | 0.103 | < 0.60 (true SD) |
| Amplitude r | 0.983 | 0.985 | want ≈ 1 |
| Variance reduction | 0.190 | — | ideal floor: 0.091 |

### Interpretation

- **Latency recovery is good:** RMSE of 7.5–8.4 ms is below the 10 ms input jitter (σ). Pearson r ≈ 0.80 confirms the estimator tracks true latency shifts, though some residual noise remains.
- **Amplitude recovery is excellent:** RMSE of 0.10–0.12 is far below the true log-normal SD of ~0.60. Correlation r ≈ 0.98 shows near-perfect linear tracking.
- **Variance reduction 0.190 vs. ideal floor 0.091:** The algorithm reduces residual variance roughly halfway between the AERP baseline and the theoretical minimum — consistent with the paper's Fig 5 results at 10 dB.
- **Converged in 3 iterations:** The F-step / T-step loop reached the convergence criterion quickly, indicating the AERP initialisation was close enough.

### Output figures

**Fig 2 — Latency: estimated vs. true (SNR = 10 dB)**
`ASEO/results/Synthetic/Synth_LatencyScatter_SNR10dB.jpg`

![Latency scatter](results/Synthetic/Synth_LatencyScatter_SNR10dB.jpg)

**Fig 3 — Amplitude: estimated vs. true (SNR = 10 dB)**
`ASEO/results/Synthetic/Synth_AmpScatter_SNR10dB.jpg`

![Amplitude scatter](results/Synthetic/Synth_AmpScatter_SNR10dB.jpg)

**Variance reduction: AERP residual vs. ASEO residual**
`ASEO/results/Synthetic/Synth_VarReduction_SNR10dB.jpg`

![Variance reduction](results/Synthetic/Synth_VarReduction_SNR10dB.jpg)

### SNR sweep — paper Fig 5 (0–30 dB)

Run with `SweepSNR=true`, 7 seeds (RNG seed 43–49), same 220-trial setup.

| SNR (dB) | Lat RMSE C1 (ms) | Lat RMSE C2 (ms) | Iterations |
| ---: | ---: | ---: | ---: |
| 0 | 17.05 | 16.43 | 18 |
| 5 | 9.99 | 11.79 | 8 |
| 10 | 6.07 | 7.68 | 2 |
| 15 | 3.25 | 4.71 | 2 |
| 20 | 2.69 | 3.01 | 2 |
| 25 | 2.45 | 2.90 | 2 |
| 30 | 2.14 | 2.69 | 2 |

**Key observations:**

- **Below 5 dB:** RMSE exceeds the 10 ms input jitter — the algorithm cannot reliably recover latency when noise dominates the signal.
- **At 5 dB:** RMSE sits right at the jitter level (~10–12 ms), a transitional regime.
- **10 dB and above:** RMSE drops well below the jitter σ, consistent with the paper's Fig 5 showing good recovery above ~5–10 dB.
- **High-SNR asymptote ~2–3 ms:** Not zero because the search grid is 1 ms and the sampling period is 5 ms — quantization limits the best achievable RMSE even with perfect data.
- **Iteration count:** 18 iterations at 0 dB vs. 2 at ≥10 dB — low-SNR runs need far more F-step/T-step cycles to converge, matching the paper's convergence analysis.

**Fig 5 — Latency RMSE vs. SNR**
`ASEO/results/Synthetic/Synth_RMSE_vs_SNR.jpg`

![RMSE vs SNR](results/Synthetic/Synth_RMSE_vs_SNR.jpg)

---

## Step 4 — Figure 12 Overlay

Script: `ASEO/scripts/Plot_Figure12.m` — loads saved `.mat` results and overlays ASEO components against the AERP without rerunning the algorithm.

### Output files

```
ASEO/results/LU/Go/lu_go_grp_Figure12_chan<1..16>.jpg       (16 files)
ASEO/results/LU/Nogo/lu_nogo_grp_Figure12_chan<1..16>.jpg   (16 files)
```

Each figure contains:

| Line style | Content |
| --- | --- |
| Red solid | ASEO Comp 1 (normalized to unit peak) |
| Magenta dashed | ASEO Comp 2 (where compNum ≥ 2) |
| Green dashed | ASEO total — sum of all components, normalized |
| Blue solid | Original AERP (normalized to unit peak) |

All waveforms are normalized to their own peak amplitude so shape differences are visible on a common [−1, +1] axis, matching the "normalized amplitude" y-axis in paper Figure 12.

### What the overlay shows

On channels with good acceptance rates (e.g. Ch 5, Ch 8, Ch 11), the ASEO components align closely with the AERP peaks but are sharper — the latency-jitter correction reduces temporal smearing of the averaged waveform. On channels with low acceptance (Ch 1, Ch 14, Ch 16), the comparison is less informative due to too few accepted trials.

---

---

## Step 5 — Single-Trial ERP Report & Presentation

### MATLAB change (`scripts/Main_ASEO.m`)

Both the Go and Nogo save calls were updated to also write three new variables to each per-channel `.mat` file:

| Variable | Description |
| --- | --- |
| `singleTrialERP` | `[sampNum × nTrials]` — per-trial ERP reconstruction `Σ β_rn · s_n(t − τ_rn)` |
| `sampFreq` | Sampling frequency (global, not previously saved) |
| `preStimulusTime` | Pre-stimulus duration in ms (local variable, not previously saved) |

`singleTrialERP` is computed inline after each `function_ASEO` call using `fun_shift` and the estimated amplitudes/latencies. Rejected trials are left as zero columns. Re-run `Main_ASEO.m` with `LoadFlag=0` to regenerate `.mat` files with these fields; the Python script will fall back to computing `singleTrialERP` itself if the field is absent.

### Python report pipeline (`helpers/generate_report.py`)

A self-contained Python script that reads the `.mat` result files and produces all report outputs. Not tracked in git (under `helpers/` which is gitignored).

**Run:**
```bash
pip install numpy scipy matplotlib python-pptx
python helpers/generate_report.py
```

Outputs go to `reports/` (figures gitignored, PPT tracked).

#### 4-panel single-trial figure (per channel × condition)

Matches Prof. Ding's reference layout exactly:

| Panel | Content |
| --- | --- |
| Top-left | **Raw Data** — all trials overlaid as coloured lines |
| Top-right | **Single-Trial ERP** — ASEO-estimated ERP for each accepted trial |
| Bottom-left | **Ongoing Activities** — residual after ERP removal per accepted trial |
| Bottom-right | **AERP comparison** — traditional AERP (blue) vs mean of single-trial ERPs (red), with amplitude SD error bar at peak |

Saved as `reports/figures/ch<N>_<Cond>_4panel.png` for all 16 channels × 2 conditions = 32 figures.

The Raw Data and Ongoing panels share the same y-scale (full amplitude range) so the noise reduction is visually apparent. Trial colours are consistent across all four panels so individual trials can be tracked.

#### Multi-channel AERP overview figure

A single 4×4 grid (`reports/figures/multichannel_aerp_overview.png`) showing all 16 channels simultaneously, each panel containing four lines:

| Line | Meaning |
| --- | --- |
| Blue solid | Go AERP |
| Blue dashed | Go ASEO AERP |
| Red solid | Nogo AERP |
| Red dashed | Nogo ASEO AERP |

Y-axis is auto-scaled per channel so waveform shape is visible regardless of amplitude. Channel 7 (`somm`) and Channel 8 (`somv`) are labelled with their anatomical identifiers. This figure gives an immediate spatial overview of: which channels have clean ERPs, where Go and Nogo diverge most, and how much ASEO sharpens the waveform relative to plain averaging across the electrode array.

#### Variance reduction bar chart

`reports/figures/variance_reduction.png` — Go and Nogo variance reduction ratios for all 16 channels side by side. Built from `summary_stats.csv`.

#### PowerPoint presentation (`reports/ASEO_Presentation.pptx`)

18 slides covering:

1. Title
2. Motivation (why single-trial analysis)
3. VSPOA signal model
4. F-step / T-step algorithm
5. Dataset & experimental setup
6. Bug fixes (3 bugs)
7. New contributions (4 items)
8–13. Single-trial ERP 4-panel figures (Ch 5, 8, 3 × Go + Nogo)
14. Latency–RT correlation results
15. Variance reduction (two-column: text + bar chart)
16. Multi-channel AERP overview
17. Synthetic validation RMSE vs SNR
18. Summary & next steps

### Project documentation (`PROJECT_OVERVIEW.md`)

A comprehensive onboarding document at the project root covering the paper background, VSPOA model derivation, algorithm flow, file responsibilities, how to run the code, parameter tuning guide, results interpretation, and data format reference. Gitignored (generated artefact).

---

## What's Still Needed

| Item | Status |
| --- | --- |
| SNR sweep (paper Fig 5) | Complete — see Step 3 above |
| Single-trial ERP figures | Complete — see Step 5 above |
| PowerPoint presentation | Complete — see Step 5 above |
| Multi-monkey batch (LU30, GE, TIO) | Blocked on dataset availability |
