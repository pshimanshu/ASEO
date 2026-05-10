function function_FT
close all;
clear all;
scriptDir = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptDir, '..', 'src'));

global dataPath;
global sourcePath;
global sampFreq;
global freqSampNum;
global sampPeri;
global sampNum;
%global trialNum;
global figNum;
global maxIterNum;
global searchWindowSet;
global searchGrid;
global maxOrderAR;
global thresholdAmpH;
global thresholdAmpL;
global thresholdCorr;

LoadFlag=0; % if LoadFlag==0, run ASEO algorithm; else reload and plot previous results.
% go_or_nogo loops over [1,0] below (1=Go, 0=Nogo)
Name='LU'; % Monkey Name — only LU data ships with this repo (lu22_go_grp.mat / lu22_nogo_grp.mat as inputs, outputs as lu_go_grp.mat / lu_nogo_grp.mat)
chanSet=1:16;  % All 16 channels; channel # 7: somm, channel #8:somv
chanNum=length(chanSet); % Number of tested channels

%parameters for trial-rejection
thresholdAmpH = 5;   %maximum acceptable amplitude of trials, times of avergae amplitude
thresholdAmpL =0.2;  %minimum  acceptable amplitude of trials, times of avergae amplitude
thresholdCorr =0.6;  %minimum correlation with the original data

maxIterNum=5; % Maximum iteration number
maxOrderAR=20; % Maximum AR order for on-going activity
maxCompNum=3; % maximum ERP component number
searchWindowSet=[-120,120;-80,80; -60,60];  % Latency search window for each ERP component in millsecond
searchGrid=1; % Latency search step in millsecond

%
sampFreq=200; % Sampling Frequency in Hz
sampPeri=1000/sampFreq; % Sampling Period in millsecond
preStimulusTime = 100% Pre-stimulus length in millseond
preStimulusSamp = round(preStimulusTime/sampPeri); %Sample number of prestimulus

% load data and set initial parameters for each monkey
switch lower(Name)
    case {'tio'} % Paremeters for monkey TIO
        sourcePath = fullfile(scriptDir, '..', 'data', filesep); % path of the source data
        dataPath = fullfile(scriptDir, '..', 'results', filesep); % Folder to save the results
        if ~exist(dataPath, 'dir'), mkdir(dataPath); end
    combinFile('tio_', 1, 'ti03111824', 'ti21', 'ti22','ti03'); % Combine several block data
    %    combinFile('tio_', 3, 'ti10', 'tiad', 'tiae');
        dataNameGo= 'tio_go_grp'; % file name for the GO data

        dataNameNogo='tio_nogo_grp'; % File name for NOGO data
                                
        % Initial parameters
        compNumSet=[2 2 2 2 2    2 2 2 2 2   2 2 2 2 ]; % Chosen ERP component for each channel
        % Interval (in ms) of the chosen initial ERP component for each channel,
        % for example, for Channel 1, we chosen the segments [160ms, 300ms] and
        % [410ms, 598ms] of AERP as the initial ERP components%%%use the
        % real stimulus onset as zero
        %      waveformInitSet     =[60 60   60  50  50     00  50  50  60  70    50  50  50  50 200  200; ...
        %                           200 160 140 220 170    110 120 170 170 290   140 150 200 170 399  399; ...
        %                           310 200 200 300 180    120 250 200 200 195   200 220 220 200 310  210; ...
        %                           498 400 498 490 498    498 400 498 350 300   450 450 498 450 398  398];
        waveformInitSet=[60 60   60  50  50     00  50  50  60  0      33  15  50  0   21 ; ...
                         200 160 140 220 170    110 120 170 170 200    187 100 200 170   242 ; ...
                         310 200 200 300 180    120 200 200 200 200    200 104 220   180 257; ...
                         498 400 498 490 498    498 450 498 350 500    400 250 498   400 450;];%%%only chan #11 12 14 were selected

        case {'lu'} % Paremeters for monkey Lui
        sourcePath = fullfile(scriptDir, '..', 'data', filesep);
        combinFile('lu_', 1, 'lu22_');
        dataNameGo= 'lu_go_grp';
        dataNameNogo='lu_nogo_grp';

        % % % % parameters of lu22go_grp
        compNumSet=[2 2 2 2 2    2 2 2 2 2   2 2 2 2 1   1];
        waveformInitSet=[ 60  60  80  50  50     80  50  50  50  60    50  50  80 100 200  200; ...
            140 130 150 150 200    220 200 125 150 130   150 150 200 200 399  399; ...
            200 180 200 200 250    230 250 140 200 180   160 160 220 220 310  310; ...
            360 300 340 340 399    395 345 345 350 320   300 300 499 300 399  399];

    case {'ge'}  % Paremeters for monkey GE
        %    sourcePath='E:\Document\lzxu\my program\dVCA\Monkey_GE\';
        %    dataPath='E:\Document\lzxu\my program\Estimation\dataMonkey_GE\';
        sourcePath = fullfile(scriptDir, '..', 'data', filesep);
        dataPath = fullfile(scriptDir, '..', 'results', 'GE_dis', '111406', filesep);
        if ~exist(dataPath, 'dir'), mkdir(dataPath); end
        combinFile('ge_', 1, 'ge57_61_70', 'ge58', 'ge59','ge60');
        dataNameGo= 'ge_go_grp_1115';
        dataNameNogo='ge_nogo_grp_1115';
        % % % parameters of GE
        compNumSet=[2 2 2 2 2   2 2 2 2 2   2 2 2 2];
        waveformInitSet =[  0  00 50  00  50      60   0  100  00    00    00  00  50  00; ...
                          100 200 150 200 150    150  140 280  200  200   155 140 180 200; ...
                          110 200 160 200 160    150  140 290  200  200   156 141 190 210; ...
                          300 400 400 499 400    400  400 499  499  499   499 499 499 499; ...
            ];
end;

% load the source data
load([sourcePath dataNameNogo '.mat']);
data(:,chanSet,:)=detrend(squeeze(data(:,chanSet,:)));%!!!!!!!
dataAllNogo=data;

%!!!!!!!!!!!!!!!!!!!
load([sourcePath dataNameGo '.mat']);
data(:,chanSet,:)=detrend(squeeze(data(:,chanSet,:)));%!!!!!!!
dataAllGo=data;
%%%rt in current space is the rt from go trials
%%%%%%%%%%%%%%%switch with line 105
clear data;


dataPreStiGo=dataAllGo(1:preStimulusSamp,:,:); % preStimulus signal
dataGo=dataAllGo(1:end,:,:);                   % Chosen the signal for test
dataPreStiNogo=dataAllNogo(1:preStimulusSamp,:,:);
dataNogo=dataAllNogo(1:end,:,:);


[sampNum, chanNumTotal, trialNumNogo]=size(dataNogo); % SampNum: Sample number; chanNumTotal: total channel number; tiralNumNogo: Nogo trial Number
[sampNum, chanNumTotal, trialNumGo]=size(dataGo); % SampNum: Sample number; chanNumTotal: total channel number; tiralNumNogo: GO trial Number

chanNum=length(chanSet); % channel number for test
%%%%%%%%%%%%%%%%%%%%
for go_or_nogo = [1, 0]
if go_or_nogo==1
    dataPath = fullfile(scriptDir, '..', 'results', 'LU', 'Go', filesep);
else
    dataPath = fullfile(scriptDir, '..', 'results', 'LU', 'Nogo', filesep);
end
if ~exist(dataPath, 'dir'), mkdir(dataPath); end
figNum=0;
for kkk=1:chanNum
    chanNo=chanSet(kkk); % Tested channel #
    figNum=chanNo*15;
    if go_or_nogo==1 %% go trials
        resultName=[dataPath dataNameGo num2str(chanNo) '_Go.mat']; % Path and file name to save results
    elseif go_or_nogo==0 %% no go trials
        resultName=[dataPath dataNameNogo num2str(chanNo) '_Nogo.mat'];
    end



    if LoadFlag==1 % if LoadFlag==1, reload the saved result; else re-run the program
        load(resultName);
    else

        %%%%%%%%%%%%%%%%%
        % preprocessing data
        dataChanNogo=squeeze(dataNogo(:,chanNo,:));
        dataPreStiChanNogo = squeeze( dataPreStiNogo(:,chanNo,:) );
        dataChanNogo=dataChanNogo - ones(sampNum,1)* mean(dataPreStiChanNogo,1); % Subtract the baseline
        dataAERPNogo(:,kkk)=mean(dataChanNogo,2); % AERP for the NOGO data

        dataChanGo=squeeze(dataGo(:,chanNo,:));%
        dataPreStiChanGo = squeeze( dataPreStiGo(:,chanNo,:) );
        dataChanGo=dataChanGo - ones(sampNum,1)* mean(dataPreStiChanGo,1); % Subtract the baseline
        dataAERPGo(:,kkk)=mean(dataChanGo,2);

                % Plot the AERP of GO and NOGO
                figure(1);
                plot((1:sampPeri:(sampNum*sampPeri))-100, dataAERPGo(:,kkk), '-', (1:sampPeri:(sampNum*sampPeri))-100, dataAERPNogo(:,kkk), '-.');
                ylabel('amplitude (arb. units)');
                xlabel('time (ms)');
                legend('Go', 'Nogo');
                title('AERP for all trials');
                grid on;
                myboldify1;
        %         print('-deps',[dataPath dataName '_AERP_' num2str(chanNo) '.eps']); % Save the plot in a *.eps file


        % Set the initial ERP waveforms according to the pre-setted parameters
        compNum=compNumSet(chanNo);
        waveformInit = zeros(sampNum, compNum);
        for compNo=1:compNum
            startTime=waveformInitSet(2*compNo-1, chanNo)+preStimulusTime;
            endTime=waveformInitSet(2*compNo, chanNo)+preStimulusTime;
            startSamp=round(startTime/sampPeri)+1;
            endSamp = round(endTime/sampPeri)+1;
            if (endSamp <= startSamp)
                disp('Invalid input! ');
            end;
            if startSamp<1
                startSamp=1;
            end;
            if endSamp>sampNum
                endSamp=sampNum;
            end;
            if go_or_nogo==1
                %if compNo==1
%                     temp=max(abs(dataAERPNogo(:, kkk)));
%                     waveformInit(:, compNo)=dataAERPNogo(:, kkk)./temp;
%                 else
                temp=max(abs(dataAERPGo(startSamp:endSamp, kkk)));
                waveformInit(startSamp:endSamp, compNo)=dataAERPGo(startSamp:endSamp, kkk)./temp;
                
            elseif go_or_nogo==0
                temp=max(abs(dataAERPNogo(startSamp:endSamp, kkk)));
                waveformInit(startSamp:endSamp, compNo)=dataAERPNogo(startSamp:endSamp, kkk)./temp;
            end
        end;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % ASEO algorithm
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Do zero-padding and FFT to the signal and initial waveforms
        zeroPadNum=ceil( (max(waveformInitSet(:)) -  min(waveformInitSet(:)))/sampPeri);  % zero-padding number
        freqSampNum=2.^(ceil(log2(sampNum+zeroPadNum)))*2;
        waveformInitFreq=fft(waveformInit, freqSampNum); % Fourier transform of the initial waveform

        if go_or_nogo==1
            dataFreqGo=fft(dataChanGo, freqSampNum);    % Fourier transform of the signal
            [ampEst, latencyEst, waveformEst,coeffAR,noiseFreq,sigma,residualSignalTime, rejectFlag,errEst]=function_ASEO(dataFreqGo, waveformInitFreq);

            % save the results
            save(resultName, 'ampEst', 'latencyEst', 'waveformEst','coeffAR','noiseFreq','sigma','residualSignalTime', 'rejectFlag',...
                'compNumSet', 'waveformInitSet','compNum', 'dataChanGo','dataChanNogo','dataAERPNogo', 'dataAERPGo','chanNo','sampNum');
        elseif go_or_nogo==0
            dataFreqNogo=fft(dataChanNogo, freqSampNum);
            % Perform ASEO algorithm
            [ampEst, latencyEst, waveformEst,coeffAR,noiseFreq,sigma,residualSignalTime, rejectFlag,errEst]=function_ASEO(dataFreqNogo, waveformInitFreq);

            save(resultName, 'ampEst', 'latencyEst', 'waveformEst','coeffAR','noiseFreq','sigma','residualSignalTime', 'rejectFlag',...
                'compNumSet', 'waveformInitSet','compNum', 'dataChanGo','dataChanNogo','dataAERPNogo', 'dataAERPGo','chanNo','sampNum');
        end

    end;



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Show the results
if go_or_nogo==1
    dataName=dataNameGo;
elseif go_or_nogo==0
    dataName=dataNameNogo;
end


    rejectIndex=find(rejectFlag); % Rejected trial #
    acceptIndex=find(~rejectFlag);  % Accepted trial #
    % Plot the AERP of GO and NOGO
%     figure(figNum-1);
%     plot((1:sampPeri:(sampNum*sampPeri))-100, dataAERPGo(:,kkk), '-', (1:sampPeri:(sampNum*sampPeri))-100, dataAERPNogo(:,kkk), '-.');
%     ylabel('amplitude (arb. units)');
%     xlabel('time (ms)');
%     legend('Go', 'Nogo');
%     title('AERP for all trials');
%     grid on;
%     myboldify1;
%     print('-djpeg',[dataPath dataName '_AERPGOandNogo_' num2str(chanNo) '.jpg']); % Save the plot in a *.eps file


    %-------------------------------------------
    % plot the variances of residual signals after removing ERPs
    figure(figNum)
    var_ori=mean( dataChanGo.*dataChanGo, 2) - mean(dataChanGo,2).^2 ; % variance of residual signal after removing AERP
    temp=real(residualSignalTime(1:sampNum,acceptIndex));   var_red = mean(temp.*temp,2) - mean(temp,2).^2; % variance of residual signal after removing AERP
    plot((1:sampPeri:(sampNum*sampPeri))-preStimulusSamp, var_ori, '--b', (1:sampPeri:(sampNum*sampPeri))-preStimulusSamp,var_red, '-r');
    ylabel('Power');
    xlabel('Time (ms)');
    legend('AERP', 'ASEO');
    title('variance of residual signal');
    grid on;
    axis([-preStimulusSamp (sampNum*sampPeri)-preStimulusTime 0  1.2*max(var_ori)])  ;
    myboldify1;
    print('-djpeg',[dataPath dataName '_Variance_' num2str(chanNo) '.jpg']);


    %---------------------------------------
    % Plot AERP and recovered AERP from the estimated ERPs
    figNum=figNum+1;
    figure(figNum);
    RestoreAERP=zeros(sampNum, 1);
    AERP=zeros(sampNum, 1);
    if go_or_nogo==1;
        trialNumber=trialNumGo;
    elseif go_or_nogo==0
        trialNumber=trialNumNogo;
    end

    for trialNo = 1:trialNumber
        if (rejectFlag(trialNo)==1)
            continue;
        end;
        if go_or_nogo==1
            AERP=AERP+ dataChanGo(:,trialNo);
        elseif go_or_nogo==0
            AERP=AERP+ dataChanNogo(:,trialNo);
        end

        for compNo=1:compNum
            tmp=waveformEst(:,compNo);
            RestoreAERP = RestoreAERP + ampEst(trialNo, compNo).*  fun_shift(tmp, latencyEst(trialNo, compNo), 1);
        end;
    end;
    RestoreAERP=(RestoreAERP)/length(acceptIndex);
    AERP=AERP/length(acceptIndex);
    residualAERP=real(mean(residualSignalTime(1:sampNum,:),2));
    plot((1:sampPeri:(sampNum*sampPeri))-preStimulusTime, AERP,'-b'); %
    hold on;
    plot((1:sampPeri:(sampNum*sampPeri))-preStimulusTime, real(RestoreAERP),'--r');
    hold on;
    legend('AERP', 'Recovered AERP')
    ylabel('Amplitude (uV)');
    xlabel('Time (ms)');
    grid on;
    axis([-preStimulusTime (sampNum*sampPeri)-preStimulusTime 1.2*min(AERP(:,1))  1.2*max(AERP(:,1))])  ;
    myboldify1;
    print('-djpeg',[dataPath dataName '_RecoveredAERP_' num2str(chanNo) '.jpg']);


%     %----------------------------------
%     % plot AERP GO and NOGO
    figNum=figNum+1;
    figure(figNum);
    plot((1:sampPeri:(sampNum*sampPeri))-preStimulusTime, dataAERPGo(:,1),'-r');
    hold on;
    plot((1:sampPeri:(sampNum*sampPeri))-preStimulusTime, dataAERPNogo(:,1),'--b');
    for compNo=1:compNum
        plot( [1 1]*waveformInitSet(2*compNo-1, chanNo), [1.2*min(dataAERPGo(:,1))  1.2*max(dataAERPGo(:,1))],'-.g');
        hold on;
        plot( [1 1]*waveformInitSet(2*compNo, chanNo), [1.2*min(dataAERPGo(:,1))  1.2*max(dataAERPGo(:,1))],'-.k');
        hold on;
    end;
    ylabel('Amplitude (uV)');
    xlabel('Time (ms)');
    legend('Go', 'Nogo');
    title('AERP for all the trials');
    grid on;
    axis([-preStimulusTime (sampNum*sampPeri)-preStimulusTime 1.2*min(dataAERPGo(:,1))  1.2*max(dataAERPGo(:,1))])  ;
    myboldify1;
    print('-djpeg',[dataPath dataName '_AERP_' num2str(chanNo) '.jpg']);
    %   print('-depsc',[dataPath dataName '_AERP_' num2str(chanNo) '.eps']);


    %----------------------------------------
    % plot estimated ERPs
    figNum=figNum+1;
    figure(figNum);
    plot((1:sampPeri:(sampNum*sampPeri))-100, real(waveformEst(:,1)*mean(ampEst(:,1))), '-b');
    hold on;
    if (compNum>1)
        plot((1:sampPeri:(sampNum*sampPeri))-preStimulusTime, real(waveformEst(:,2)*mean(ampEst(:,2))), '--r');
    end
    hold on;
    if (compNum>2)
        plot((1:sampPeri:(sampNum*sampPeri))-preStimulusTime, real(waveformEst(:,3)*mean(ampEst(:,3))), '-.k');
    end
    switch compNum
        case {1}
            legend('Comp.');
        case {2}
            legend('Comp. 1', 'Comp. 2');
        otherwise
            legend('Comp. 1', 'Comp. 2', 'Comp. 3');
    end;
    temp=mean(ampEst); temp=max(temp);
    if isnan(temp) || temp==0, temp=1; end
    axis([-1*preStimulusTime ((sampNum-5)*sampPeri-preStimulusTime) -1*temp  1.2*temp])  ;
    condStr = 'Nogo'; if go_or_nogo==1, condStr = 'Go'; end
    nRej = length(rejectIndex); nTot = length(rejectFlag);
    disp(['[Chan ' num2str(chanNo) ' | ' condStr ' | ch ' num2str(kkk) '/' num2str(chanNum) '] ' ...
          'reject ratio: ' num2str(nRej) '/' num2str(nTot) ' (' num2str(100*nRej/nTot,'%.1f') '%)']);
    ylabel('Amplitude (uV)');
    xlabel('Time (ms)');
    title(['Chan ' num2str(chanNo) ' ' condStr ' — reject ' num2str(nRej) '/' num2str(nTot)]);
    myboldify1;
    print('-djpeg',[dataPath dataName '_ASEO_ERP_chan' num2str(chanNo)  '.jpg']);


    %---------------------------------------------
    %distribition of latency and amplitude

    for compNo=1:compNum
        figNum=figNum+1;
        figure(figNum);

        temp=latencyEst(acceptIndex,compNo)*sampPeri;
        [N X] =hist(temp,[-80:5:80]);
        plot(X, N/sum(N));
        xlabel('Estimated latency (ms)');
        ylabel('Probability');
        title(['Comp' num2str(compNo)]);grid on;
        myboldify1;
        print('-djpeg',[dataPath dataName '_ASEO_latencyDist_chan' '_chan' num2str(chanNo) 'Comp' num2str(compNo) '.jpg']);

        figNum=figNum+1;
        figure(figNum);

        temp=ampEst(acceptIndex,compNo);
        [N X] =hist(temp,50);
        plot(X, N/sum(N));
        xlabel('Estimated amplitude (uV)');
        ylabel('Probability');
        title(['Comp' num2str(compNo)]);grid on;
        myboldify1;
        print('-djpeg',[dataPath dataName '_ASEO_AmpDist_chan' '_chan' num2str(chanNo) 'Comp' num2str(compNo) '.jpg']);
    end;


    %--------------------------------
    % plot estimated latency vs. reponse time
    if go_or_nogo==1

        for compNo = 1:compNum
            figNum=figNum+1;
            figure(figNum);

            temp1=latencyEst(acceptIndex,compNo)*sampPeri-mean(latencyEst(acceptIndex,compNo)*sampPeri);   tempLen=length(temp1);
             
            plot(temp1 +(2*rand(tempLen,1)-1)*2  ,rt(acceptIndex)+(2*rand(1,tempLen)-1)*2, 'rx' );%%%????????
            temp2=rt(acceptIndex)-mean(rt(acceptIndex));
            temp3=temp1-temp2';
            LR = 1- norm(temp3).^2/(norm(temp2).^2+norm(temp1).^2);%??????
            ylabel('Response time (ms)');
            xlabel('Estimated latency (ms)');
            title(['Comp' num2str(compNo)]);grid on;
            myboldify1;
            print('-djpeg',[dataPath dataName '_ASEO_latencyCorr_chan'  num2str(chanNo) 'Comp' num2str(compNo) '.jpg']);
        end;
    %--------------------------------------------
    % amplitude vs. response time


    for compNo = 1:compNum
        figNum=figNum+1;
        figure(figNum);
        temp1=ampEst(acceptIndex,compNo);   tempLen=length(temp1);
        plot(temp1 ,rt(acceptIndex), 'rx' );
        temp2=rt(acceptIndex)-mean(rt(acceptIndex));
        corr=temp1'*temp2'/norm(temp1)/norm(temp2);
        ylabel('Response time (ms)');
        xlabel('Estimated amplitude ');
        title(['Comp' num2str(compNo)]);grid on;
        %axis([0, 300, 220,360]);
        myboldify1;
        print('-djpeg',[dataPath dataName '_ASEO_latencyvsEstamp_chan' '_dVCA_chan' num2str(chanNo) 'Comp' num2str(compNo) '.jpg']);
    end;

    end
    %--------------------------------------
    % print the ongoing activity
    %sampNumFreq= 2.^(ceil(log2(sampNum)))*4;
    %temp=real( residualSignalTime(1:sampNum,:)); temp=temp-ones(sampNum,1)*mean(temp, 1);
    %[noiseFreq, coeffARGo, sigmaGo] =functionNoiseEstFreqLDA_BIC(temp, rejectFlag,sampNumFreq);
    [ongoing]=drawOnging(mean(coeffAR,2),mean(sigma));
    print('-djpeg',[dataPath dataName '_ASEO_Ongoing_chan' '_chan' num2str(chanNo) '.jpg']);
    hold on;

 end; % end for kkk
end; % end for go_or_nogo
%
% %load handel
% %sound(y,Fs)