%Adding signal together
funtion AggregateSignal

file = dir('C:\Users\Iva\Desktop\HFO-Spike Training Files\Seizures Files Prof Jiruska\FB003854-241115_000802-dec.mat')

load dir

Chan_1 = sigTbl.Data(1)
Chan_2 = sigTbl.Data(2)
%Chan_3 = sigTbl.Data(3(time))
%Chan_4 = sigTbl.Data(4(time))
%Chan_5 = sigTbl.Data(5(time))
%Chan_6 = sigTbl.Data(6(time))

time = (117700:117900)

Signal_aggregate = sum(Chan_1, Chan_2)


