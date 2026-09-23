

Data = load('jk20151111_1-151126_043115-A2b_B-d-999.mat');
DataField = fieldnames(Data);
dlmwrite('FileName.txt', Data.(DataField{1}));
