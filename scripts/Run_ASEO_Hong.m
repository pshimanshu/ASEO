% Run ASEO single trial analysis on epoched data
% modified and written by Xiangfei Hong @ UF 2019-04

% modify data dir, ASEO parameters, etc before use

clear all;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

load('RI2017_HC_Subject_Clean.mat', '-mat');
Ns = length(RI2017_HC_Subject);

% load channels
load('RI2017_locs60_Final.mat', '-mat');
FCz = find(strcmpi('FCz',{locs.labels}));

% results
restoreAERP_All = [];                       % ASEO ERP: subs x times
AERP_All = [];                              % AERP: subs x times
SingleTrial_ERP_ASEO = struct('ERP',[]);    % times x trials
SingleTrial_EEG = struct('EEG',[]);         % times x trials

% ASEO settings
global freqSampNum;          freqSampNum=1024;
global maxIterNum;           maxIterNum = 5;
global searchWindowSet;      searchWindowSet=[-10,10;-10,10;-30,30;-20,20;-10,10;-10,10;-10,10];
global searchGrid;           searchGrid=1;
global maxOrderAR;           maxOrderAR=25;
global thresholdAmpH;        thresholdAmpH=10;
global thresholdAmpL;        thresholdAmpL=0.001;
global thresholdCorr;        thresholdCorr=0.001;
global sampFreq;             sampFreq=250;
global sampPeri;             sampPeri=1000/sampFreq;
global sampNum;              sampNum=500;

% save ASEO settings
ASEO = struct();
ASEO.sampFreq=250;
ASEO.sampPeri=1000/sampFreq;
ASEO.sampNum=500;
ASEO.freqSampNum=1024;
ASEO.maxIterNum = 5;
ASEO.searchWindowSet=[-10,10;-10,10;-30,30;-20,20;-10,10;-10,10;-10,10];
ASEO.searchGrid=1;
ASEO.maxOrderAR=25;
ASEO.thresholdAmpH=10;
ASEO.thresholdAmpL=0.001;
ASEO.thresholdCorr=0.001;


% loop
for s = 1:Ns % number of subject
    
    
    % load data
    EEG = pop_loadset('filename', [RI2017_HC_Subject(s).id '_preprocessed.set'],...
                      'filepath', [data_dir 'EEG\Preprocessing_Target_Epochs\']);
    
    
    % run ASEO
    %time2use = -400:4:996;% -1000:4:996
    %time2use_idx   = dsearchn(EEG.times',time2use');
    data_FCz = squeeze(EEG.data(FCz,:,:)); % time x trials
    
    erp_FCz = mean(data_FCz,2);
    
    erp_FCz_Filt = eegfilt(erp_FCz',250,0,20);
    
    range1 =  50:4:150;   range1_idx = dsearchn(EEG.times',range1');
    range2 = 150:4:250;   range2_idx = dsearchn(EEG.times',range2');
    range3 = 250:4:400;   range3_idx = dsearchn(EEG.times',range3');
    range4 = 400:4:600;   range4_idx = dsearchn(EEG.times',range4');
    
    waveformInit = zeros(sampNum,1);
    waveformInit(range1_idx,1) = erp_FCz_Filt(range1_idx);
    waveformInit(range2_idx,2) = erp_FCz_Filt(range2_idx);
    waveformInit(range3_idx,3) = erp_FCz_Filt(range3_idx);
    waveformInit(range4_idx,4) = erp_FCz_Filt(range4_idx);
    
    waveformInitFreq = fft(waveformInit, freqSampNum);
    data_FCz_Freq = fft(data_FCz, freqSampNum);
    
    [ampEst,latencyEst,waveformEst,coeffAR,noiseFreq,sigma,...
        residualSignalTime,rejectFlag,errEst]=...
        function_ASEO(data_FCz_Freq,waveformInitFreq);
    
    if ~isempty(find(isnan(waveformEst)))
        error('NaN found!') % sometimes happen
    end
    
    restoreERP = []; % time x trials
    data_acc = [];
    ongoing = [];
    
    for i = 1:size(data_FCz,2) % trials
        compest1 = ampEst(i,1)*fun_shift1(waveformEst(:,1),latencyEst(i,1),1);
        compest2 = ampEst(i,2)*fun_shift1(waveformEst(:,2),latencyEst(i,2),1);
        compest3 = ampEst(i,3)*fun_shift1(waveformEst(:,3),latencyEst(i,3),1);
        compest4 = ampEst(i,4)*fun_shift1(waveformEst(:,4),latencyEst(i,4),1);
        
        ERPest = compest1+compest2+compest3+compest4;
        
        restoreERP = [restoreERP, ERPest];
        ongoing = [ongoing, data_FCz(:,i)-ERPest];
    end
    
    restoreAERP = real(mean(restoreERP,2));
    
    
    % save results
    SingleTrial_ERP_ASEO(s).ERP = real(restoreERP);
    SingleTrial_EEG(s).EEG = data_FCz;
    restoreAERP_All(s,:) = restoreAERP';
    AERP_All(s,:) = erp_FCz_Filt';
    
    
end


 % save single-trial ERPdata
save('SingleTrial_ERP_ASEO_FCz.mat', 'SingleTrial_ERP_ASEO', 'SingleTrial_EEG', 'restoreAERP_All', 'AERP_All', 'ASEO', '-mat');

