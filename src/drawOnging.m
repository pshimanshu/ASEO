
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ongoing]=drawOnging(coeffAR,sigma)
% Plot the power spectrum of the AR model
% INPUT
% coeffAR:  AR Coefficients
% sigma: power of the input white noise in AR model
% OUTPUT:
% ongoing: Power spectrum

 global sampFreq;
 global sampNum;
 global sampPeri;
 global figNum;
 
 figNum=figNum+1;
 figure(figNum);

 freqSampNum=2.^(ceil(log2(sampNum)))*4;
 
 [maxAROrder, trialNum]=size(coeffAR);
 
 freqSeq=linspace(0,sampFreq,freqSampNum ).';
 omegaFreq=2*pi*freqSeq;
 
 ongoing=zeros(freqSampNum,trialNum);
 for trialNo=1:trialNum
     x=ones(freqSampNum,1) - exp(-j*omegaFreq*(1:maxAROrder)*sampPeri/1000)*coeffAR(:, trialNo);
     ongoing(:,trialNo)=sigma(trialNo)*(abs(1./x)).^2;
 end;

      plot(freqSeq, ongoing);
      xlabel('Frequency (Hz)');
      ylabel('Power spectral density');
      title('power of ongoing activity after ASEO removal of ERP');
      grid;
      myboldify1;
      tmp=max(abs(ongoing));
      axis([0 sampFreq/4 0 tmp]);
%end; 