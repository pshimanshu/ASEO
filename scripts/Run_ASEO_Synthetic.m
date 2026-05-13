% Run_ASEO_Synthetic.m
% Validate ASEO on synthetic VSPOA data with known ground-truth latencies
% and amplitudes.  Reproduces paper Figures 2, 3, and (optionally) 5.
%
% Set SweepSNR=false for a single-SNR run (fast); true to sweep 0..30 dB.

close all; clear all;
scriptDir = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptDir, '..', 'src'));

% ---- output folder -----------------------------------------------------
outDir = fullfile(scriptDir, '..', 'results', 'Synthetic');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% ---- user flags --------------------------------------------------------
SweepSNR  = false;   % true => reproduce Fig 5 RMSE vs SNR curves (~7 runs)
SingleSNR = 10;      % dB used for scatter plots (Figs 2 & 3)
RNG_SEED  = 42;
UseGTInit = false;   % true => init with ground-truth waveforms instead of AERP
                     %         (diagnostic: isolates init quality from noise-model issues)

% ---- ASEO global parameters -------------------------------------------
global sampFreq sampPeri sampNum freqSampNum
global maxIterNum maxOrderAR searchWindowSet searchGrid
global thresholdAmpH thresholdAmpL thresholdCorr

sampFreq = 200;
sampPeri = 1000 / sampFreq;   % 5 ms
sampNum  = 120;
maxIterNum  = 20;   % 10 was too few for convergence with colored noise
maxOrderAR  = 20;
searchGrid  = 1;   % ms

% Search windows are generous relative to the 10 ms latency SD
searchWindowSet = [-40, 40; -40, 40];   % [compNum x 2] in ms

thresholdAmpH = 5;
thresholdAmpL = 0.2;
thresholdCorr = 0.5;

% ======================================================================
% Single-SNR run — scatter plots (paper Figs 2 & 3)
% ======================================================================
fprintf('Running ASEO on synthetic data at SNR = %d dB ...\n', SingleSNR);

[data, latencyTrue, ampTrue, waveformTrue] = ...
    generateSyntheticVSPOA(SingleSNR, 'seed', RNG_SEED);

comp_centres_ms = [100, 300];
half_win_ms     = 60;
if UseGTInit
    % Use ground-truth waveforms: bypasses AERP quality entirely.
    % If RMSE improves sharply here vs. AERP init, init quality is a bottleneck.
    waveformInit = waveformTrue;
    fprintf('  (using ground-truth waveform initialisation)\n');
else
    aerp         = mean(data, 2);
    waveformInit = zeros(sampNum, 2);
    for c = 1:2
        t1 = max(1,       round((comp_centres_ms(c) - half_win_ms) / sampPeri) + 1);
        t2 = min(sampNum, round((comp_centres_ms(c) + half_win_ms) / sampPeri) + 1);
        seg  = aerp(t1:t2);
        peak = max(abs(seg));  if peak == 0, peak = 1; end
        waveformInit(t1:t2, c) = seg / peak;
    end
end

zeroPadNum  = ceil(2 * max(abs(searchWindowSet(:))) / sampPeri);
freqSampNum = 2^(ceil(log2(sampNum + zeroPadNum))) * 2;

dataFreq         = fft(data,          freqSampNum);
waveformInitFreq = fft(waveformInit,  freqSampNum);

[ampEst, latencyEst, waveformEst, coeffAR, noiseFreq, sigma, ...
    residualSignalTime, rejectFlag, ~] = function_ASEO(dataFreq, waveformInitFreq);

acceptIdx  = find(~rejectFlag);
rejectIdx  = find(rejectFlag);
nAcc       = length(acceptIdx);
nTot       = length(rejectFlag);
fprintf('Accepted %d / %d trials (%.1f%% accepted)\n', nAcc, nTot, 100*nAcc/nTot);

% Latency RMSE in ms
lat_true_ms = latencyTrue(acceptIdx,:) * sampPeri;
lat_est_ms  = latencyEst (acceptIdx,:) * sampPeri;
rmse_lat    = sqrt(mean((lat_est_ms - lat_true_ms).^2, 1));

% Amplitude RMSE
amp_true_acc = ampTrue(acceptIdx,:);
amp_est_acc  = ampEst (acceptIdx,:);
rmse_amp     = sqrt(mean((amp_est_acc - amp_true_acc).^2, 1));

% Pearson correlation: distinguishes scale/offset bias from pure noise
r_lat = diag(corr(lat_true_ms, lat_est_ms));
r_amp = diag(corr(amp_true_acc, amp_est_acc));

fprintf('Latency  RMSE — Comp1: %.2f ms,  Comp2: %.2f ms  (input sigma = 10 ms; want RMSE << 10)\n', rmse_lat(1), rmse_lat(2));
fprintf('         corr — Comp1: r=%.3f,    Comp2: r=%.3f\n', r_lat(1), r_lat(2));
fprintf('Amplitude RMSE — Comp1: %.3f,     Comp2: %.3f  (true SD~0.60; want RMSE << 0.60)\n', rmse_amp(1), rmse_amp(2));
fprintf('         corr — Comp1: r=%.3f,    Comp2: r=%.3f\n', r_amp(1), r_amp(2));

% ---- Figure 2: latency scatter (estimated vs. true) -------------------
figure(2); clf;
compColors = {'b', 'r'};
for c = 1:2
    subplot(1, 2, c);
    scatter(lat_true_ms(:,c), lat_est_ms(:,c), 10, compColors{c}, 'filled', 'MarkerFaceAlpha', 0.5);
    hold on;
    lim = max(abs([lat_true_ms(:,c); lat_est_ms(:,c)])) * 1.1;
    plot([-lim lim], [-lim lim], 'k--', 'LineWidth', 1.2);
    xlabel('True latency (ms)');
    ylabel('Estimated latency (ms)');
    title(sprintf('Comp %d  RMSE = %.2f ms', c, rmse_lat(c)));
    axis([-lim lim -lim lim]); grid on; axis square;
end
sgtitle(sprintf('Fig 2 — Latency: Est vs. True  (SNR = %d dB)', SingleSNR));
print('-djpeg', fullfile(outDir, sprintf('Synth_LatencyScatter_SNR%ddB.jpg', SingleSNR)));

% ---- Figure 3: amplitude scatter (estimated vs. true) -----------------
figure(3); clf;
for c = 1:2
    subplot(1, 2, c);
    scatter(amp_true_acc(:,c), amp_est_acc(:,c), 10, compColors{c}, 'filled', 'MarkerFaceAlpha', 0.5);
    hold on;
    lim = max([amp_true_acc(:,c); amp_est_acc(:,c)]) * 1.1;
    plot([0 lim], [0 lim], 'k--', 'LineWidth', 1.2);
    xlabel('True amplitude');
    ylabel('Estimated amplitude');
    title(sprintf('Comp %d  RMSE = %.3f', c, rmse_amp(c)));
    axis([0 lim 0 lim]); grid on; axis square;
end
sgtitle(sprintf('Fig 3 — Amplitude: Est vs. True  (SNR = %d dB)', SingleSNR));
print('-djpeg', fullfile(outDir, sprintf('Synth_AmpScatter_SNR%ddB.jpg', SingleSNR)));

% ---- Variance reduction check -----------------------------------------
t_ms = (1:sampNum)' * sampPeri - sampPeri;
var_ori  = var(data, 0, 2);
var_res  = var(real(residualSignalTime(1:sampNum, acceptIdx)), 0, 2);
varRatio = sum(var_res) / sum(var(data(:, acceptIdx), 0, 2));
snr_lin_actual = 10^(SingleSNR/10);
varRatio_ideal = 1 / (1 + snr_lin_actual);   % floor for a perfect estimator at this SNR
fprintf('Variance reduction ratio: %.3f  (ideal floor at SNR=%ddB: %.3f;  paper real-data: ~0.29–0.30)\n', ...
    varRatio, SingleSNR, varRatio_ideal);

figure(4); clf;
plot(t_ms, var_ori, '--b', t_ms, var_res, '-r');
xlabel('Time (ms)'); ylabel('Power');
legend('AERP residual', 'ASEO residual'); grid on;
title(sprintf('Variance reduction ratio = %.3f', varRatio));
print('-djpeg', fullfile(outDir, sprintf('Synth_VarReduction_SNR%ddB.jpg', SingleSNR)));

% ======================================================================
% Optional: SNR sweep — RMSE curves (paper Fig 5)
% ======================================================================
if SweepSNR
    snr_vec     = 0:5:30;
    nSNR        = length(snr_vec);
    rmse_lat_vs_snr = zeros(nSNR, 2);
    rmse_amp_vs_snr = zeros(nSNR, 2);

    fprintf('\nSweeping SNR 0..30 dB (%d runs)...\n', nSNR);
    for si = 1:nSNR
        fprintf('  SNR = %2d dB ... ', snr_vec(si));

        [data_s, latTrue_s, ampTrue_s, ~] = ...
            generateSyntheticVSPOA(snr_vec(si), 'seed', RNG_SEED + si);

        aerp_s = mean(data_s, 2);
        waveformInit_s = zeros(sampNum, 2);
        for c = 1:2
            t1 = max(1,       round((comp_centres_ms(c) - half_win_ms) / sampPeri) + 1);
            t2 = min(sampNum, round((comp_centres_ms(c) + half_win_ms) / sampPeri) + 1);
            seg = aerp_s(t1:t2);  pk = max(abs(seg));  if pk==0, pk=1; end
            waveformInit_s(t1:t2, c) = seg / pk;
        end

        freqSampNum = 2^(ceil(log2(sampNum + zeroPadNum))) * 2;
        dF_s  = fft(data_s,           freqSampNum);
        wF_s  = fft(waveformInit_s,   freqSampNum);
        [aE, lE, ~, ~, ~, ~, ~, rF, ~] = function_ASEO(dF_s, wF_s);

        acc_s = find(~rF);
        lat_err = (lE(acc_s,:) - latTrue_s(acc_s,:)) * sampPeri;
        amp_err =  aE(acc_s,:) - ampTrue_s(acc_s,:);
        rmse_lat_vs_snr(si,:) = sqrt(mean(lat_err.^2, 1));
        rmse_amp_vs_snr(si,:) = sqrt(mean(amp_err.^2, 1));

        fprintf('lat RMSE = [%.2f, %.2f] ms\n', ...
            rmse_lat_vs_snr(si,1), rmse_lat_vs_snr(si,2));
    end

    figure(5); clf;
    subplot(1, 2, 1);
    plot(snr_vec, rmse_lat_vs_snr(:,1), 'b-o', snr_vec, rmse_lat_vs_snr(:,2), 'r-s');
    xlabel('SNR (dB)'); ylabel('Latency RMSE (ms)');
    legend('Comp 1', 'Comp 2'); grid on;
    title('Fig 5 — Latency RMSE vs SNR');

    subplot(1, 2, 2);
    plot(snr_vec, rmse_amp_vs_snr(:,1), 'b-o', snr_vec, rmse_amp_vs_snr(:,2), 'r-s');
    xlabel('SNR (dB)'); ylabel('Amplitude RMSE');
    legend('Comp 1', 'Comp 2'); grid on;
    title('Fig 5 — Amplitude RMSE vs SNR');

    print('-djpeg', fullfile(outDir, 'Synth_RMSE_vs_SNR.jpg'));

    save(fullfile(outDir, 'Synth_SNR_sweep.mat'), ...
        'snr_vec', 'rmse_lat_vs_snr', 'rmse_amp_vs_snr');
    fprintf('SNR sweep results saved.\n');
end

fprintf('\nAll synthetic validation outputs saved to %s\n', outDir);
