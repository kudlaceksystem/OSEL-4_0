function convert_OSEL;

S=pwd;
[fname,pname] = uigetfile('*.mat','Load data');
cd(pname)
load(fname);

f=size(sigTbl.Data,1)
for i=1:f; 
EEG_Selection_all(:,i)=double(sigTbl.Data{i,1});
end
EEG_SamplingFreq=sigTbl.Fs(1);

m=size(fname,2);
savefile=[fname(1,1:m-4),'_pj.mat']
save(savefile, 'EEG_Selection_all', 'EEG_SamplingFreq');
cd(S)
