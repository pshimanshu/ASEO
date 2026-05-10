% Run ASEO single trial analysis on epoched data
% Code written for the CNV

clear;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

pathname = 'C:\Users\Vladimir Liu\SkyDrive\';
filename = 'Sub14_EpochsArtRej_zm.mat';

setInd = 1;   % 1: Cue Left, 2: Cue Right
chanInd = 2;  % 1: P3, 2: P4
chan = [7 8];

% chan = 18;    % Channel Cz
% chan = 21;    % Channel FC1
% chan = 22;    % Channel FC2

% chan = 18;    % Channel Cz
% chan = 22;   % Channel FC2
% chan = 6;    % Channel C4
% chan = 24;   % Channel CP2
% chan = 23;    % Channel CP1
% chan = 7;    % Channel P3
% chan = 8;    % Channel P4
% chan = 31;   % Channel POZ

fname = strcat(pathname,filename);
load(fname);

if setInd == 1
    data1 = dataCueLeft_zm;       % Cue Left
else if setInd == 2
    data1 = dataCueRight_zm;      % Cue Right
    end
end

dataChan = data1(chan,:,:);
if chanInd == 1      % Channel P3
    data1chan = squeeze(data1(1,:,:));
else if chanInd == 2      % Channel P4
        data1chan = squeeze(data1(2,:,:));
    end
end

% data1chan = squeeze(data1(chan,:,:));

[npts,ntrl] = size(data1chan);

% Filter 0~35Hz
% dataFilt = zeros(npts,ntrl);
% for i = 1:ntrl
%     dataFilt(:,i) = eegfilt(data_chan(:,i)',250,0,35,0,30,0);
% end
% data_chan1 = data_chan;
% data_chan = dataFilt;

n1 = 1:npts;
figure;
plot(n1,data1chan);
figure;
erp = mean(data1chan,2);
erpFilt = eegfilt(erp',250,0,12,0,30,0);
% plot(n,erp);grid on;
% hold on;
plot(n1,erpFilt,'r');grid on;
figure;
plot((n1-125)*4,erpFilt,'b');grid on;

global freqSampNum;
global maxIterNum;
global searchWindowSet;
global searchGrid;
global maxOrderAR;
global thresholdAmpH;
global thresholdAmpL;
global thresholdCorr;
global sampFreq;
global sampPeri;
global sampNum;

sampFreq=250;
sampPeri=1000/sampFreq;
sampNum=500;
freqSampNum=1024;
maxIterNum = 1;
searchWindowSet=[-10,10;-10,10;-30,30;-20,20;-10,10;-10,10;-10,10];
searchGrid=1;
maxOrderAR=25;
thresholdAmpH=10;
thresholdAmpL=0.001;
thresholdCorr=0.001;

range1 = 163:202;
range2 = 202:350;
range3 = 350:500;
% range4 = 368:500;

waveformInit = zeros(sampNum,1);
% waveformInit(83:102,1) = erp(83:102);
waveformInit(range1,1) = erpFilt(range1);
waveformInit(range2,2) = erpFilt(range2);
waveformInit(range3,3) = erpFilt(range3);
% waveformInit(range4,4) = erpFilt(range4);

waveformInitFreq = fft(waveformInit, freqSampNum);
Data = data1chan;
dataFreq = fft(Data,freqSampNum);

[ampEst,latencyEst,waveformEst,coeffAR,noiseFreq,sigma,...
    residualSignalTime,rejectFlag,errEst]=...
    function_ASEO(dataFreq,waveformInitFreq);

restoreERP = [];
restoreAERP = zeros(sampNum,1);
data_acc = [];
ongoing = [];

for i = 1:size(Data,2)
    compest1 = ampEst(i,1)*fun_shift1(waveformEst(:,1),latencyEst(i,1),1);
    compest2 = ampEst(i,2)*fun_shift1(waveformEst(:,2),latencyEst(i,2),1);
    compest3 = ampEst(i,3)*fun_shift1(waveformEst(:,3),latencyEst(i,3),1);
%     compest4 = ampEst(i,4)*fun_shift1(waveformEst(:,4),latencyEst(i,4),1);
    
    ERPest=compest1+compest2+compest3;
    
    restoreERP = [restoreERP, ERPest];
    restoreAERP = restoreAERP + ERPest;
    ongoing = [ongoing, Data(:,i)-ERPest];
end

restoreAERP = restoreAERP / ntrl;

figure;
plot((n1-125)*4,restoreAERP,'--');
hold on;
plot((n1-125)*4,erp,'r');
title('Restored AERP vs. AERP');
legend('Restored AERP','AERP');
grid on;
xlabel('Time msec')
% myboldify1;


figure;
plot((n1-125)*4,restoreERP);
grid on;
title('Single-Trial ERP')
xlabel('Time msec');
% myboldify1;


figure;
plot((n1-125)*4,waveformEst(:,1));
hold on;
plot((n1-125)*4,waveformEst(:,2),'r');
plot((n1-125)*4,waveformEst(:,3),'g');
% plot((n1-125)*4,waveformEst(:,4),'k');
% plot((n-50)*4,waveformEst(:,5),'y');
% plot((n-50)*4,waveformEst(:,6),'m');
% plot((n-50)*4,waveformEst(:,7),'c');
hold off;
legend('Comp1','Comp2','Comp3');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot ERP Image to examine trial-by-trial amplitude information of the
% estimated single-trial ERPs
restoreERP_eeglab = zeros(1,npts,ntrl);
data1chan_eeglab = zeros(1,npts,ntrl);

restoreERP_eeglab(1,:,:) = real(restoreERP);
data1chan_eeglab(1,:,:) = data1chan;

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

EEG = pop_importdata('dataformat','array','nbchan',1,'data','restoreERP_eeglab','srate',250,'pnts',500,'xmin',-0.5);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','Single-trial ERP','gui','off'); 
EEG = eeg_checkset( EEG );
figure; pop_erpimage(EEG,1, [1],[],'Single-trial ERP',5,1,{},[],'' ,'yerplabel','\muV','erp','on','cbar','on');

EEG = pop_importdata('dataformat','array','nbchan',1,'data','data1chan_eeglab','srate',250,'pnts',500,'xmin',-0.5);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','Raw Data','gui','off'); 
EEG = eeg_checkset( EEG );
figure; pop_erpimage(EEG,1, [1],[],'Raw Data',5,1,{},[],'' ,'yerplabel','\muV','erp','on','cbar','on');

eeglab redraw;
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save single-trial ERP estimation results
% save('C:\Users\Vladimir Liu\SkyDrive\SingleTrialERP\Sub14_CueRight_P4.mat','restoreERP','restoreAERP','ongoing','chan');
    
    
    
    





