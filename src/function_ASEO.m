function [ampEst, latencyEst, waveformEst,coeffAR,noiseFreq,sigma, residualSignalTime,rejectFlag,corrEst]=function_ASEO(dataFreq, waveformInitFreq)
% Desscription: Single-trial analysis
% INPUT----
% dataFreq:  Observed data samples in frequency domain
% waveformInitFreq: Initial ERP components in frequency domain
% OUTPUT----
% ampEst  : Estimates of ERP components
% latency : estimates of ERP components
% waveformEst: Estimates of ERP waveforms in time domain
% coeffAR : Estimated AR coefficients of on-going activity
% noiseFreq:  Power spectrum of on-going activity fitted in AR model
% sigma    :  Power of the input white noise of AR model for on-going activity
% residualSignalTime: Residual signal after removing ERPs in time domain
% rejectFlag: Each element of rejectFlag indicating that the corresponding
%              tiral should be rejected or not. For example, rejectFlag(9)==1 means 
%              the 9th trial is rejected.
% corrEst   : Correlation bwtween the origianl data and the recoved signal

global sampFreq; % sampling frequency
global sampPeri; % sampling period
global sampNum; % sample Numer
global maxIterNum; % maximum iteration number
global maxOrderAR; % maximum AR order of on-going activity 

 trialNum=size(dataFreq,2); % trial Number
 [sampNumFreq, compNum]=size(waveformInitFreq); % Sample number and component number
 dataFreq=dataFreq(1:(sampNumFreq/2+1),:); % Get the signal from [0, pi).
  
 %-------------------------
  % initialization
  waveformEstFreq=waveformInitFreq(1:(sampNumFreq/2+1),:); % ERP waveform initialization
  ampEst=ones( trialNum, compNum);  % ERP amplitude initialization
  latencyEst=zeros( trialNum, compNum); % ERP latency initialization
  noiseFreq=ones(sampNumFreq/2+1, trialNum); % Initialization of the power spectrum of on-going activity
  coeffAR=zeros(maxOrderAR,trialNum); % Initialization of the AR coefficients
  rejectFlag=zeros(trialNum,1); % Initialization of the reject flags
  
  %--------------------------
  %  Estimation of the ERP amplitudes and latencies 
  for compNo=1:compNum
     [latencyEst ampEst] = functionLatencyAmpEstFreq(dataFreq, waveformEstFreq, ampEst, latencyEst, compNo, noiseFreq);
   end;
  

 %---------------------------------
 % Do iteration of ERP and on-going estimation
 PureDataEstFreqOld=sum(waveformEstFreq,2)*ones(1,trialNum);
  for iterNo=1:maxIterNum
      
       %reject trails 
       [rejectFlag,corrEst]=rejectTrial(waveformEstFreq, ampEst, latencyEst, dataFreq);
       
      % ERP estimaton in frequency domain
       [waveformEstFreq ampEst latencyEst, residualSignal] = functionERPEstFreq(dataFreq, waveformEstFreq, ampEst, latencyEst, noiseFreq,rejectFlag);
      
       % Convergence? If convergence, stop iteration
       PureDataEstFreq=dataFreq-residualSignal;
       temp=sum(sum(abs(PureDataEstFreqOld - PureDataEstFreq).^2,1),2)./sum(sum(abs(PureDataEstFreq).^2,1),2);
       PureDataEstFreqOld=PureDataEstFreq;
       if temp<=1e-3
           iterNo 
           break;
       end;
       
      
     % on-going activity estimation in Time Domain
      residualSignal=[residualSignal; conj(residualSignal((sampNumFreq/2):-1:2,:))];
      residualSignalTime=ifft(residualSignal,[],1);
      noiseFreq=noiseFreq(1:(sampNumFreq/2+1),:);
      temp=real( residualSignalTime(1:sampNum,:)); %temp=temp-ones(sampNum,1)*mean(temp, 1);
      
      [noiseFreq, coeffAR, sigma] =functionNoiseEstFreqLDA_BIC(temp, rejectFlag,sampNumFreq); % L
      noiseFreq=noiseFreq(1:(sampNumFreq/2+1),:);

       %adjust the latency such that the mean of latencies is 0.
      freqSeq=2*pi/sampNumFreq*(0:(sampNumFreq/2))';
      latencyEstMean=round(mean(latencyEst,1));
      latencyEst=latencyEst-kron(ones(trialNum,1), latencyEstMean);
      for compNo=1:compNum
         waveformEstFreq(:, compNo)=waveformEstFreq(:,compNo).*exp(-j*freqSeq*latencyEstMean(compNo));;
      end;
  end;

  
  waveformEstFreq=[waveformEstFreq; conj(waveformEstFreq((sampNumFreq/2):-1:2,:))];
  waveformEst=ifft(waveformEstFreq);
  waveformEst=waveformEst(1:sampNum, :);
  temp=max(abs(waveformEst));
  waveformEst=waveformEst./(ones(sampNum,1)*temp);
  ampEst=ampEst.*(ones(trialNum,1)*temp);
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [waveformEstFreq, ampEst, latencyEst, residualSignal] =...
          functionERPEstFreq(dataFreq, waveformEstFreq, ampEst, latencyEst, noiseFreq, rejectFlag);
  % Estimate the ERP waveforms, ampltiudes and latencies in frequency domain
  % INPUT----
  % dataFreq:  Observed data samples in frequency domain
  % waveformEstFreq: The most-recent estimates of the ERP waveforms in frequency domain
  % ampEst         : The most-recent estimates of ERP amplitudes
  % latencyEst     : The most-recent estimates of ERP latencies
  % noiseFreq      : The most=recent estimates of spectrum of on-going activity
  % rejectFlag     : Reject flags
  % OUTPUT ----
  % waveformEstFreq: Updated estimates of the ERP waveforms in frequency domain
  % ampEst         : Updated estimates of ERP amplitudes
  % latencyEst     : Updated estimates of ERP latencies
  % residualSignal : Residual signal after removing ERPs in frequency domain
     
  global sampFreq;
  global sampPeri;
  global sampNum;
  
  trialNum=size(dataFreq,2);
  [sampNumFreq, compNum]=size(waveformEstFreq); % Sample number and component number
  freqSeq=2*pi/(2*sampNumFreq-2)*(0:(sampNumFreq-1))';
  
  invsqrt_noiseFreq=1./sqrt(noiseFreq);
  acceptIndex=find(~rejectFlag);
  for kkk=1:sampNumFreq
       A_tilde=ampEst(acceptIndex,:).*exp(-j*freqSeq(kkk)*latencyEst(acceptIndex,:)).* (invsqrt_noiseFreq(kkk, acceptIndex).'*ones(1,compNum)) ;  
       X_tilde = dataFreq(kkk,acceptIndex).'.*invsqrt_noiseFreq(kkk,acceptIndex).';
       S_tilde=(A_tilde'* A_tilde)\(A_tilde'*X_tilde);
       
       waveformEstFreq(kkk,:) = S_tilde.';   
   end;
     
     % update the latency and amplitude estimates
   for compNo=1:compNum
      [latencyEst ampEst] = functionLatencyAmpEstFreq(dataFreq, waveformEstFreq, ampEst, latencyEst, compNo,noiseFreq);
   end;
      
% Compute residual signal by removing ERPs
  residualSignal=zeros(sampNumFreq, trialNum);
  for trialNo=1:trialNum
          residualSignal(:,trialNo)=dataFreq(:,trialNo)- ( exp(-j*freqSeq* latencyEst(trialNo,:) ).*waveformEstFreq )* ampEst(trialNo, :).';
   end;
 
     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [latencyEst, ampEst]=functionLatencyAmpEstFreq(dataFreq, waveformEstFreq, ampEst, latencyEst, compNo, noiseFreq)
    % Estimate the ERP ampltiudes and latencies in frequency domain
  % INPUT----
  % dataFreq:  Observed data samples in frequency domain
  % waveformEstFreq: The most-recent estimates of the ERP waveforms in frequency domain
  % ampEst         : The most-recent estimates of ERP amplitudes
  % latencyEst     : The most-recent estimates of ERP latencies
  % compNo         : Component # 
  % noiseFreq      : The most=recent estimates of spectrum of on-going activity
  % OUTPUT ----
   % ampEst         : Updated estimates of ERP amplitudes
  % latencyEst     : Updated estimates of ERP latencies
  global sampFreq;
  global sampPeri;
  global sampNum; 
  global searchWindowSet; %Latency search window defined in main_ASEO.m  
  global searchGrid; % Latency search step
  
  inv_noiseFreq=1./noiseFreq;
  
  dataFreq([1 end],:)= dataFreq([1 end],:)/2;
  waveformEstFreq([1 end], :)= waveformEstFreq([1 end], :)/2;
  [trialNum]=size(dataFreq,2);
  [sampNumFreq, compNum]=size(waveformEstFreq);
  freqSeq=2*pi/(2*sampNumFreq-2)*(0:(sampNumFreq-1))';
    
  % Estimate ERP latencies and amptlitudes trial by trial 
  for trialNo=1:trialNum
                   
             % Signal after removing other ERP component
             ampEstTmp=ampEst(trialNo, [1:compNo-1 compNo+1:end]);
             waveformEstFreqTmp=waveformEstFreq(:,[1:compNo-1 compNo+1:end]);
             latencyEstTmp=latencyEst(trialNo, [1:compNo-1 compNo+1:end]);
             signal=dataFreq(:,trialNo) -( exp(-j*freqSeq* latencyEstTmp ).*waveformEstFreqTmp ) *ampEstTmp.';  
             
%              %Estimate ERP latency
             temp=inv_noiseFreq(:,trialNo).*conj(signal).*(waveformEstFreq(:,compNo));
             fft_point=(2*sampNumFreq-2)*sampPeri/searchGrid;
             temp_tau=fft(temp, fft_point); % Do Fourier transform
             temp_tau=fftshift(temp_tau);
             searchWindow_index1=round(searchWindowSet(compNo,1)/searchGrid) + round(fft_point/2);
             searchWindow_index2=round(searchWindowSet(compNo,2)/searchGrid) + round(fft_point/2);
             ruo=real( temp_tau(searchWindow_index1:searchWindow_index2 ) );
              [peak, index]=max(ruo); % Find the peak value
             latencyEst(trialNo, compNo)=searchWindowSet(compNo,1)*sampFreq/1000 + (index-1)*searchGrid*sampFreq/1000; %searchWindow(index) ;%
 
             
          % Esimate the ERP amplitudes using Least-Squares
          A=  exp(-j*freqSeq* latencyEst(trialNo,:) ).*waveformEstFreq; 
          A_tmp=A.*(inv_noiseFreq(:,trialNo) * ones(1, compNum)) ;
          x= dataFreq(:,trialNo);
          ampEstTmp=real(A'*A_tmp)\real(A_tmp'*x);
          ampEst(trialNo, :)= ampEstTmp.';
  end;

     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rejectFlag, corrEst]=rejectTrial(waveformEstFreq, ampEst, latencyEst,  dataFreq)
% Desscription: Reject trials
% INPUT----
% waveformEstFreq: Estimats of ERP waveforms in frequency domain
% ampEst  : Estimates of ERP components
% latency : estimates of ERP components
% dataFreq:  Observed data samples in frequency domain
% OUTPUT----
% rejectFlag: Each element of rejectFlag indicating that the corresponding
%              tiral should be rejected or not. For example, rejectFlag(9)==1 means 
%              the 9th trial is rejected.
% corrEst   : Correlation bwtween the origianl data and the recoved signal

global thresholdAmpH;  %maximum acceptable amplitude of trials, times of avergae amplitude
global thresholdAmpL;  % minimum  acceptable amplitude of trials, times of avergae amplitude
global thresholdCorr;  %minimum correlation with the original data

[compNum]=size(waveformEstFreq,2);
[sampNumFreq, trialNum]=size(dataFreq);
compNum=size(waveformEstFreq,2);
freqSeq=2*pi/(2*sampNumFreq-1)*(0:(sampNumFreq-1))';
rejectFlag=zeros(trialNum,1);
corrEst=zeros(trialNum,1);

for compNo=1:compNum
  ampEstTmp=ampEst(:,compNo);
   ampEstMean=mean(ampEstTmp);
   % check the amplitudes for each trial 
   rejectFlag=rejectFlag | (ampEstTmp < thresholdAmpL*ampEstMean) | (ampEstTmp > thresholdAmpH*ampEstMean);
end;

% check the correction between the original data samples and estimated ERPs
for trialNo=1:trialNum
         signal= exp(-j*freqSeq* latencyEst(trialNo,:) ).*waveformEstFreq(:,:);     
         signal=signal*ampEst(trialNo, :).';
         
         corrTmp=real( signal'*dataFreq(:,trialNo))/norm(signal)/norm(dataFreq(:,trialNo)) ; 
         rejectFlag(trialNo)=rejectFlag(trialNo) | (real(corrTmp) < thresholdCorr );
         corrEst(trialNo)=corrTmp;
 end;


   


 
  