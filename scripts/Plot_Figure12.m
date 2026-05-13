% Plot_Figure12.m — Reproduce paper Figure 12: AERP vs. ASEO component overlay
%
% Loads saved ASEO results (produced by Main_ASEO with LoadFlag=0) and
% overlays the ASEO-estimated ERP component waveforms on the same axes as
% the original AERP, for both Go and Nogo conditions and all 16 channels.
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

conditions = struct('name', {dataNameGo,  dataNameNogo}, ...
                    'label', {'Go',        'Nogo'}, ...
                    'flag',  {1,            0});

for ci = 1:numel(conditions)
    cond     = conditions(ci);
    condPath = fullfile(scriptDir, '..', 'results', 'LU', cond.label, filesep);
    outPath  = fullfile(scriptDir, '..', 'results', 'LU', cond.label, filesep);

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
        % Variables now in workspace: ampEst, latencyEst, waveformEst,
        %   rejectFlag, compNum, dataAERPGo, dataAERPNogo, chanNo, sampNum

        tVec = (1:sampPeri:(sampNum * sampPeri)) - preStimulusTime;

        % AERP for this condition
        if cond.flag == 1
            aerp = dataAERPGo(:, 1);
        else
            aerp = dataAERPNogo(:, 1);
        end

        acceptIndex = find(~rejectFlag);

        % Sum of scaled ASEO component waveforms (using mean amplitude over
        % accepted trials — same scaling used in the current per-component
        % subplot in Main_ASEO)
        aseoSum = zeros(sampNum, 1);
        compColors = {'-r', '--m', '-.k'};
        compHandles = gobjects(compNum, 1);

        fig = figure('Visible', 'off');
        hold on;

        % Individual components
        for compNo = 1:compNum
            meanAmp = mean(ampEst(acceptIndex, compNo));
            wave    = real(waveformEst(1:sampNum, compNo)) * meanAmp;
            aseoSum = aseoSum + wave;
            h = plot(tVec, wave, compColors{min(compNo, end)}, 'LineWidth', 1.5);
            compHandles(compNo) = h;
        end

        % AERP and total reconstructed AERP
        hAERP  = plot(tVec, aerp,    '-b',  'LineWidth', 2);
        hTotal = plot(tVec, aseoSum, '--g', 'LineWidth', 1.5);

        % Axis limits
        yAll = [aerp; aseoSum];
        yMin = 1.2 * min(yAll);
        yMax = 1.2 * max(yAll);
        if yMin == yMax, yMax = yMin + 1; end
        xlim([tVec(1), tVec(end)]);
        ylim([yMin, yMax]);

        % Labels and legend
        xlabel('Time (ms)', 'FontSize', 12);
        ylabel('Amplitude (\muV)', 'FontSize', 12);
        title(sprintf('Chan %d %s — AERP vs. ASEO Components (Fig. 12)', ...
              chanNo, cond.label), 'FontSize', 12);

        legendLabels = cell(compNum + 2, 1);
        for compNo = 1:compNum
            legendLabels{compNo} = sprintf('ASEO Comp. %d', compNo);
        end
        legendLabels{compNum + 1} = 'AERP';
        legendLabels{compNum + 2} = 'ASEO total';
        legend([compHandles; hAERP; hTotal], legendLabels, 'Location', 'best');

        grid on;
        myboldify1;

        outFile = fullfile(outPath, sprintf('%s_Figure12_chan%d.jpg', cond.name, chanNo));
        print('-djpeg', outFile);
        close(fig);
        fprintf('Saved %s\n', outFile);
    end
end

fprintf('Done. Figure 12 overlays written to results/LU/Go/ and results/LU/Nogo/.\n');
