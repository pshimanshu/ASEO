% Plot_Figure12.m — Reproduce paper Figure 12: AERP vs. ASEO component overlay
%
% Loads saved ASEO results (produced by Main_ASEO with LoadFlag=0) and
% overlays the ASEO-estimated ERP component waveforms on the same axes as
% the original AERP, for both Go and Nogo conditions and all 16 channels.
%
% Waveforms are normalized to their own peak absolute amplitude so that
% shape can be compared directly on a common [-1, +1] scale.  This matches
% paper Figure 12 ("normalized amplitude" axis).
%
% Usage: run this script after Main_ASEO has saved results to results/LU/.

close all;
scriptDir = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptDir, '..', 'src'));

sampFreq    = 200;
sampPeri    = 1000 / sampFreq;
preStimulusTime = 100;   % ms

dataNameGo   = 'lu_go_grp';
dataNameNogo = 'lu_nogo_grp';

conditions = struct('name',  {dataNameGo,  dataNameNogo}, ...
                    'label', {'Go',         'Nogo'}, ...
                    'flag',  {1,             0});

for ci = 1:numel(conditions)
    cond     = conditions(ci);
    condPath = fullfile(scriptDir, '..', 'results', 'LU', cond.label, filesep);
    outPath  = condPath;

    if cond.flag == 1
        suffix = '_Go.mat';
    else
        suffix = '_Nogo.mat';
    end

    matFiles = dir(fullfile(condPath, [cond.name '*' suffix]));
    if isempty(matFiles)
        warning('No result files found in %s — run Main_ASEO first.', condPath);
        continue;
    end

    for fi = 1:numel(matFiles)
        load(fullfile(condPath, matFiles(fi).name));
        % Variables in workspace: ampEst, latencyEst, waveformEst,
        %   rejectFlag, compNum, dataAERPGo, dataAERPNogo, chanNo, sampNum

        tVec = (1:sampPeri:(sampNum * sampPeri)) - preStimulusTime;

        % Bug fix: dataAERPGo/Nogo is [sampNum x chanNum]; column index
        % equals chanNo (since chanSet=1:16 so kkk==chanNo).
        if cond.flag == 1
            aerp_raw = dataAERPGo(:, chanNo);
        else
            aerp_raw = dataAERPNogo(:, chanNo);
        end

        acceptIndex = find(~rejectFlag);

        % Normalize AERP to unit peak so shape is on [-1, +1]
        aerpPeak = max(abs(aerp_raw));
        if aerpPeak == 0 || isnan(aerpPeak), aerpPeak = 1; end
        aerp_norm = aerp_raw / aerpPeak;

        % Build normalized ASEO component waveforms
        compColors  = {'-r', '--m', '-.k'};
        compHandles = gobjects(compNum, 1);
        aseoSum_raw = zeros(sampNum, 1);

        for compNo = 1:compNum
            meanAmp = mean(ampEst(acceptIndex, compNo));
            wave    = real(waveformEst(1:sampNum, compNo)) * meanAmp;
            aseoSum_raw = aseoSum_raw + wave;
        end

        fig = figure('Visible', 'off');
        hold on;

        % Plot individual components (each normalized to its own peak)
        for compNo = 1:compNum
            meanAmp  = mean(ampEst(acceptIndex, compNo));
            wave_raw = real(waveformEst(1:sampNum, compNo)) * meanAmp;
            wavePeak = max(abs(wave_raw));
            if wavePeak == 0 || isnan(wavePeak), wavePeak = 1; end
            h = plot(tVec, wave_raw / wavePeak, compColors{min(compNo, numel(compColors))}, ...
                     'LineWidth', 1.5);
            compHandles(compNo) = h;
        end

        % ASEO total: normalize the summed waveform to its own peak
        totalPeak = max(abs(aseoSum_raw));
        if totalPeak == 0 || isnan(totalPeak), totalPeak = 1; end
        hTotal = plot(tVec, aseoSum_raw / totalPeak, '--g', 'LineWidth', 1.5);

        % AERP last so it sits on top
        hAERP = plot(tVec, aerp_norm, '-b', 'LineWidth', 2);

        ylim([-1.3, 1.3]);
        xlim([tVec(1), tVec(end)]);

        xlabel('Time (ms)', 'FontSize', 12);
        ylabel('Normalized amplitude', 'FontSize', 12);
        title(sprintf('Chan %d %s — AERP vs. ASEO Components (Fig. 12)', ...
              chanNo, cond.label), 'FontSize', 12);

        legendLabels = cell(compNum + 2, 1);
        for compNo = 1:compNum
            legendLabels{compNo} = sprintf('ASEO Comp. %d', compNo);
        end
        legendLabels{compNum + 1} = 'ASEO total';
        legendLabels{compNum + 2} = 'AERP';
        legend([compHandles; hTotal; hAERP], legendLabels, 'Location', 'best');

        grid on;
        myboldify1;

        outFile = fullfile(outPath, sprintf('%s_Figure12_chan%d.jpg', cond.name, chanNo));
        print('-djpeg', outFile);
        close(fig);
        fprintf('Saved %s\n', outFile);
    end
end

fprintf('Done. Figure 12 overlays written to results/LU/Go/ and results/LU/Nogo/.\n');
