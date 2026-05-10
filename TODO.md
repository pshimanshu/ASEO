# ASEO — Next Steps

Ordered by priority. Steps requiring additional monkey datasets (LU30, GE, TIO) are placed last.

---

## Step 1 — B: Complete Real-Data Results (Existing LU Data)

- [ ] Fix typo in PSD plot title: `"AESO"` → `"ASEO"` in `drawOnging.m`
- [ ] Investigate Comp 1 parameter tuning:
  - Latency distribution is hitting ±80 ms search boundaries — widen `searchWindowSet` for Comp 1 or inspect `waveformInitSet` initialization window
  - Estimated Comp 1 waveform is jagged — consider adjusting component time window in `waveformInitSet`
- [ ] Run analysis on all 16 channels (currently only channel 5 via `chanSet=[5]`)
- [ ] Run both Go and Nogo conditions across all channels

---

## Step 2 — C: Add Quantitative Reporting

- [ ] Save per-run summary statistics to a `.txt` or `.csv` file:
  - Trial acceptance rate (accepted / total)
  - Per-component mean latency ± SD
  - Per-component mean amplitude ± SD
  - Latency–RT correlation (r and p-value) — currently computed in `Main_ASEO.m` but discarded
  - Variance reduction ratio (ASEO vs. AERP) — paper reports ~0.29–0.30
  - AR model order selected by BIC
  - PSD peak frequency of ongoing activity
- [ ] These values are already computed; they just need to be saved/printed

---

## Step 3 — A: Validate Algorithm with Synthetic Data (Ground Truth)

- [ ] Implement `generateSyntheticVSPOA.m` — simulate trials per paper Example 1 (Section V-A-1):
  - R = 220 trials, T = 120 samples, 200 Hz sampling rate
  - 2 ERP components with Gaussian latency shifts (μ=0, σ=10 ms)
  - Log-normal amplitude scaling (median=1, shape=0.5)
  - Additive AR ongoing activity at varying SNR
- [ ] Run `function_ASEO` on synthetic data with known ground-truth latencies and amplitudes
- [ ] Compute RMSE: `sqrt(mean((latencyEst - latencyTrue).^2))` and same for amplitude
- [ ] Reproduce paper Figure 2 (latency scatter: estimated vs. true) and Figure 3 (amplitude scatter)
- [ ] Optionally sweep SNR (0–30 dB) and reproduce Figure 5 RMSE curves

---

## Step 4 — D: Reproduce Paper Figure 12 (AERP vs. Component Overlay)

- [ ] Overlay the ASEO-estimated component waveforms on the same axes as the original AERP
  - Currently `lu_go_grp_AERP_5.jpg` and `lu_go_grp_ASEO_ERP_chan5.jpg` are separate plots
  - Paper Figure 12 shows them together for direct visual comparison
- [ ] Add axis labels consistent with paper (normalized amplitude or µV, time in ms)
- [ ] Produce for both Go and Nogo conditions

---

## Step 5 — E: Multi-Monkey Batch Analysis (Requires Additional Data)

> **Blocked on:** obtaining LU30, GE, and/or TIO monkey datasets.

- [ ] Once additional monkey datasets are available, extend `Main_ASEO.m` or write a batch driver to loop over subjects
- [ ] Produce per-subject and averaged summary statistics (Step 2 output per monkey)
- [ ] Compare latency–RT correlations across subjects and conditions (Go vs. Nogo)
- [ ] Cross-monkey variance reduction comparison
- [ ] Reproduce paper's two-site (parietal + somatosensory) analysis if both cortical channels are available in the new datasets
