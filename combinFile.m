function combinFile(outfileName, fileNum, fileName1, fileName2, fileName3, fileName4)
global dataPath;
global sourcePath;

go_ext='go_grp';
nogo_ext='nogo_grp';

go_trialNumAll=0;
nogo_trialNumAll=0;

load([sourcePath fileName1 go_ext '.mat']);
[sampNum, chanNum, go_trialNum1]=size(data);
go_data1=data;
go_rt1=rt;
go_trialNumAll=go_trialNumAll+go_trialNum1;

load([sourcePath fileName1 nogo_ext '.mat']);
[sampNum, chanNum, nogo_trialNum1]=size(data);
nogo_data1=data;
%nogo_rt1=rt;
nogo_trialNumAll=nogo_trialNumAll+nogo_trialNum1;

if fileNum>=2

    load([sourcePath fileName2 go_ext '.mat']);
    [sampNum, chanNum, go_trialNum2]=size(data);
    go_data2=data;
    go_rt2=rt;
    go_trialNumAll=go_trialNumAll+go_trialNum2;

    load([sourcePath fileName2 nogo_ext '.mat']);
   [sampNum, chanNum, nogo_trialNum2]=size(data);
   nogo_data2=data;
   %nogo_rt2=rt;
   nogo_trialNumAll=nogo_trialNumAll+nogo_trialNum2;
   

end;

if fileNum>=3

    load([sourcePath fileName3 go_ext '.mat']);
    [sampNum,chanNum, go_trialNum3]=size(data);
    go_data3=data;
    go_rt3=rt;
    go_trialNumAll=go_trialNumAll+go_trialNum3;

    load([sourcePath fileName3 nogo_ext '.mat']);
   [sampNum, chanNum, nogo_trialNum3]=size(data);
   nogo_data3=data;
   %nogo_rt3=rt;
   
   nogo_trialNumAll=nogo_trialNumAll+nogo_trialNum3;
end;
if fileNum>=4

    load([sourcePath fileName4 go_ext '.mat']);
    [sampNum,chanNum, go_trialNum4]=size(data);
    go_data4=data;
    go_rt4=rt;
    go_trialNumAll=go_trialNumAll+go_trialNum4;

   load([sourcePath fileName4 nogo_ext '.mat']);
   [sampNum, chanNum, nogo_trialNum4]=size(data);
   nogo_data4=data;
   %nogo_rt4=rt;
   
   nogo_trialNumAll=nogo_trialNumAll+nogo_trialNum4;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data=zeros(sampNum,chanNum,go_trialNumAll);
rt=zeros(1,go_trialNumAll);

data(:,:,1:go_trialNum1)=go_data1;
rt(1,1:go_trialNum1)=go_rt1;

if fileNum>=2
    data(:,:,go_trialNum1+(1:go_trialNum2))=go_data2;
   rt(1,go_trialNum1+(1:go_trialNum2))=go_rt2;
end;

if fileNum>=3
    data(:,:,go_trialNum1+go_trialNum2+(1:go_trialNum3))=go_data3;
    rt(1,go_trialNum1+go_trialNum2+(1:go_trialNum3))=go_rt3;
end;
if fileNum>=4
    data(:,:,go_trialNum1+go_trialNum2+go_trialNum3+(1:go_trialNum4))=go_data4;
    rt(1,go_trialNum1+go_trialNum2+go_trialNum3+(1:go_trialNum4))=go_rt4;
end;
trialNum=go_trialNumAll;

 save([sourcePath outfileName go_ext '.mat'], 'data', 'rt', 'trialNum', 'sampNum', 'chanNum' );

%------------
data=zeros(sampNum,chanNum,nogo_trialNumAll);
rt=zeros(1,nogo_trialNumAll);

data(:,:,1:nogo_trialNum1)=nogo_data1;
%rt(1,1:nogo_trialNum1)=nogo_rt1;

if fileNum>=2
    data(:,:,nogo_trialNum1+(1:nogo_trialNum2))=nogo_data2;
   %rt(1,nogo_trialNum1+(1:nogo_trialNum2))=nogo_rt2;
end;
if fileNum>=3
    data(:,:,nogo_trialNum1+nogo_trialNum2+(1:nogo_trialNum3))=nogo_data3;
    %rt(1,nogo_trialNum1+nogo_trialNum2+(1:nogo_trialNum3))=nogo_rt3;
end;
if fileNum>=4
    data(:,:,nogo_trialNum1+nogo_trialNum2+nogo_trialNum3+(1:nogo_trialNum4))=nogo_data4;
    %rt(1,nogo_trialNum1+nogo_trialNum2+nogo_trialNum3+(1:nogo_trialNum4))=nogo_rt4;
end;

trialNum=nogo_trialNumAll;

save([sourcePath outfileName nogo_ext '.mat'], 'data', 'rt', 'trialNum', 'sampNum', 'chanNum' );