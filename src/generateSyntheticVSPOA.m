function [data, latencyTrue, ampTrue, waveformTrue] = generateSyntheticVSPOA(SNR_dB, varargin)
% Generate synthetic VSPOA trials following Xu et al. 2009, Example 1 (Sec. V-A-1).
%
% R=220 trials, T=120 samples, fs=200 Hz, 2 ERP components.
% Latency shifts: Gaussian(0, 10 ms).  Amplitudes: log-normal(mu=0, sigma=0.5).
% Ongoing activity: AR(2) resonant at ~10 Hz, scaled to match SNR_dB.
%
% INPUT
%   SNR_dB   : signal-to-noise ratio in dB (default 10)
%   'seed',S : optional RNG seed for reproducibility
%
% OUTPUT
%   data         : [T x R] simulated trials (time domain)
%   latencyTrue  : [R x 2] ground-truth latency shifts in samples
%   ampTrue      : [R x 2] ground-truth amplitude scalings
%   waveformTrue : [T x 2] unit-peak ERP component waveforms

if nargin < 1 || isempty(SNR_dB), SNR_dB = 10; end

for k = 1:2:length(varargin)
    if strcmpi(varargin{k}, 'seed')
        rng(varargin{k+1});
    end
end

R  = 220;   % trials
T  = 120;   % samples
fs = 200;   % Hz
sampPeri_ms = 1000 / fs;   % 5 ms/sample

sigma_tau_samples = 10 / sampPeri_ms;   % 10 ms -> 2 samples

% ---- ERP component waveforms: unit-peak Gaussian bumps -----------------
t_ms = (0:T-1)' * sampPeri_ms;
mu_ms  = [100, 300];   % component centres
sig_ms = [25,   40];   % component widths

waveformTrue = zeros(T, 2);
for c = 1:2
    g = exp(-0.5 * ((t_ms - mu_ms(c)) / sig_ms(c)).^2);
    waveformTrue(:, c) = g / max(abs(g));
end

% ---- Ground-truth per-trial parameters ---------------------------------
latencyTrue = round(sigma_tau_samples * randn(R, 2));   % integer sample shifts
ampTrue     = exp(0.5 * randn(R, 2));                   % log-normal, median=1

% ---- Assemble ERP contribution -----------------------------------------
erpSignal = zeros(T, R);
for r = 1:R
    for c = 1:2
        erpSignal(:, r) = erpSignal(:, r) + ...
            ampTrue(r, c) * circshift(waveformTrue(:, c), latencyTrue(r, c));
    end
end

% ---- AR(2) ongoing activity resonant near 10 Hz ------------------------
% AR(2) poles at radius r, angle 2*pi*f0/fs => denominator [1, -2r*cos(theta), r^2]
r_pole = 0.95;
f0_hz  = 10;
ar_denom = [1, -2*r_pole*cos(2*pi*f0_hz/fs), r_pole^2];

burnIn = 500;
wn       = randn(T + burnIn, R);
ar_noise = filter(1, ar_denom, wn);
ar_noise = ar_noise(burnIn+1:end, :);

% Scale noise to reach target SNR
P_erp   = mean(var(erpSignal));
P_noise = mean(var(ar_noise));
snr_lin = 10^(SNR_dB / 10);
noise   = sqrt(P_erp / (snr_lin * P_noise)) * ar_noise;

data = erpSignal + noise;
end
