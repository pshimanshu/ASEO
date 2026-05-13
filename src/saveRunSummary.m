function saveRunSummary(csvPath, chanNo, condStr, compNum, rejectFlag, ...
    latencyEst, ampEst, sampPeri, varReductionRatio, arOrder, psdPeakFreq, ...
    rtCorr, rtCorrP)
% Append one summary row per (channel, condition) to csvPath.
% Component-level stats use columns C1/C2/C3; unused components get NaN.
% rtCorr / rtCorrP are vectors of length compNum (NaN for Nogo).

maxComp = 3;
acceptIndex = find(~rejectFlag);
nAccept    = length(acceptIndex);
nTotal     = length(rejectFlag);
acceptRate = 100 * nAccept / nTotal;

% Build per-component stats (NaN-padded to maxComp)
latMean = nan(1, maxComp);  latSD = nan(1, maxComp);
ampMean = nan(1, maxComp);  ampSD = nan(1, maxComp);
rtCorrOut  = nan(1, maxComp);
rtCorrPOut = nan(1, maxComp);
for c = 1:compNum
    lat = latencyEst(acceptIndex, c) * sampPeri;
    amp = ampEst(acceptIndex, c);
    latMean(c) = mean(lat);
    latSD(c)   = std(lat);
    ampMean(c) = mean(amp);
    ampSD(c)   = std(amp);
    if c <= length(rtCorr) && ~isnan(rtCorr(c))
        rtCorrOut(c)  = rtCorr(c);
        rtCorrPOut(c) = rtCorrP(c);
    end
end

writeHeader = ~exist(csvPath, 'file');
fid = fopen(csvPath, 'a');
if fid == -1
    error('saveRunSummary: cannot open %s for writing', csvPath);
end

if writeHeader
    fprintf(fid, ['Condition,Channel,AcceptRate_pct,' ...
        'LatMean_C1_ms,LatSD_C1_ms,AmpMean_C1,AmpSD_C1,' ...
        'LatMean_C2_ms,LatSD_C2_ms,AmpMean_C2,AmpSD_C2,' ...
        'LatMean_C3_ms,LatSD_C3_ms,AmpMean_C3,AmpSD_C3,' ...
        'RTCorr_C1,RTCorrP_C1,RTCorr_C2,RTCorrP_C2,RTCorr_C3,RTCorrP_C3,' ...
        'VarReductionRatio,AROrder,PSDPeakFreq_Hz\n']);
end

fprintf(fid, '%s,%d,%.2f,', condStr, chanNo, acceptRate);
fprintf(fid, '%.4f,%.4f,%.4f,%.4f,', latMean(1), latSD(1), ampMean(1), ampSD(1));
fprintf(fid, '%.4f,%.4f,%.4f,%.4f,', latMean(2), latSD(2), ampMean(2), ampSD(2));
fprintf(fid, '%.4f,%.4f,%.4f,%.4f,', latMean(3), latSD(3), ampMean(3), ampSD(3));
fprintf(fid, '%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,', ...
    rtCorrOut(1), rtCorrPOut(1), rtCorrOut(2), rtCorrPOut(2), rtCorrOut(3), rtCorrPOut(3));
fprintf(fid, '%.4f,%d,%.4f\n', varReductionRatio, arOrder, psdPeakFreq);

fclose(fid);
