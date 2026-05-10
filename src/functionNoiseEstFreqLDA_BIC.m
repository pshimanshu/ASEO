function  [pwrFreq, coeffAR,inputNoisePwr] = functionNoiseEstFreqLDA_BIC(signalTime, rejectFlag,sampNumFreq)
% Use Levinson-Durbin to estimate the AR coefficicent
% Use Bayesian Information Criterion for AR order determintion
% --Input
% sigalTime:  On-going activity in time-domain
% rejectFlag: Indicating the trials that will be rejected. If would not
%            reject any trials, set rejectFlag=[0 0 0 0 ....] .
% SampNumFreq: Sample number to represent the power spectrum
%--Output
% pwrFreq   : Power spectrum of the estimated AR model
% coeffAR  : Estimated AR coefficients
% inputNoisePwr: Power of the input white noise in the AR model
global  maxOrderAR;

[sampTimeNum, trialNumOrg]=size(signalTime);
% regject the poor trails
acceptIndex=find(~rejectFlag);
signalTime=signalTime(:,acceptIndex);
[sampTimeNum, trialNum]=size(signalTime);

coeffAR=zeros(maxOrderAR,trialNum);
coeffARTrial=zeros(maxOrderAR, maxOrderAR);
costFun=zeros(maxOrderAR,1);

%  calculate the autocorrelation
ruo=zeros(1+maxOrderAR,1);
k=0;
ruo0=sum(sum(signalTime(1:end-k,:) .* conj(signalTime(k+1:end,:)), 1),2)/trialNum/sampTimeNum;

ruo=zeros(maxOrderAR,1);
for k=1:maxOrderAR
    ruo(k)=sum(sum(signalTime(1:end-k,:) .* conj(signalTime(k+1:end,:)), 1),2)/trialNum/(sampTimeNum-k);
end;

% initialize
kai=-ruo(1)/ruo0;
theta=kai;
coeffARTrial(1,1)=kai;
sigmaSquare=ruo0-abs(ruo(1)).^2/ruo0;
inputNoisePwr(1)=sigmaSquare;
costFun(1)=trialNum*sampTimeNum.*log(sigmaSquare)+4;
for n=1:maxOrderAR-1
    kai=-1*(ruo(n+1) + ruo(n:-1:1)'* theta)/sigmaSquare;
    sigmaSquare=sigmaSquare*(1-abs(kai).^2);
    theta=[theta; 0] + kai*[theta(n:-1:1); 1 ];

    coeffARTrial(1:n+1,n+1)=theta;
    inputNoisePwr(n+1)=sigmaSquare;
    costFun(n+1)=trialNum*sampTimeNum.*log(sigmaSquare)+(n)*log(trialNum*sampTimeNum); % BIC cost function
end;

[peak, orderAR]=min(costFun);
coeffAR=coeffARTrial(1:orderAR, orderAR);

% calculate the frequency response of the AR model
temp=ones(sampNumFreq, 1);
freqSeq=2*pi/sampNumFreq*(0:(sampNumFreq-1))';
for kkk=1:orderAR
    temp=temp + coeffAR(kkk).*exp(-j.*freqSeq.*kkk);
end;

% calculate the input noise power
X=signalTime(orderAR+1:end,:);
for kkk=1:orderAR
    X=X + coeffAR(kkk)*signalTime(orderAR+1-kkk:end-kkk,:);
end;
inputNoisePwr=sum(X.*conj(X),1)./(sampTimeNum-orderAR);

% calculate the power spectrum
pwrFreq=(1./ ( abs(temp).^2))*inputNoisePwr;
coeffAR=-1* kron(coeffAR, ones(1, trialNum));

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output
temp=mean(pwrFreq,2);
pwrFreqtemp=temp*ones(1,trialNumOrg);
pwrFreqtemp(:,acceptIndex)=pwrFreq;
pwrFreq=pwrFreqtemp;

temp=mean(inputNoisePwr,2);
inputNoisePwrtemp=temp*ones(1,trialNumOrg);
inputNoisePwrtemp(:,acceptIndex)=inputNoisePwr;
inputNoisePwr=inputNoisePwrtemp;
%end;