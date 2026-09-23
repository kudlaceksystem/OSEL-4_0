close all; clear
% filep = 'f:\jk20151030_3\Extracted uSeiz intercluster\';
% filep = 'g:\Kudlacek\jk20151109_1\Extracted uSeiz intercluster\';
% filep = 'g:\Kudlacek\jk20151109_2\Extracted uSeiz intercluster\';
% filep = 'j:\jk20151111_1\Extracted uSeiz intercluster\';
% filep = 'j:\jk20151111_2\Extracted uSeiz intercluster\';
% filep = 'l:\jk20151017\Extracted uSeiz intercluster\';


d = dir(filep);
filen = {d.name};
filen = filen(~[d.isdir]);
clear d
for kf = 1 : length(filen)
    load([filep, filen{kf}])
    if exist('d')
        if size(d, 1) < size(s, 2)
            d = [d; NaN(size(s, 2) - size(d, 1), size(d, 2))];
        end
        if size(d, 1) > size(s, 2)
            s = [s, NaN(size(s, 1), size(d, 1) - size(s, 2))];
        end
    end
    d(:, kf) = s(1, :)';
    alphaTailDateN(kf) = dateN;
end

save('Alpha-tails intercluster jk20151017.mat', 'd', 'fs', 'alphaTailDateN')
'Finished'