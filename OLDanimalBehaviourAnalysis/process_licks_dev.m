%% test bed
% ugly code
times = [0 1.1 2 2.9 3.5 6 8.1 9 10 12 14 15 22]';
thresh = 1.1;

test1 = diff(times)<thresh;
if times(2)-times(1) < thresh
    test1 = [1; test1];
else
    test1 = [0; test1];
end

for i = 2:numel(test1)
    if test1(i)==1
        test1(i-1)=1;
    end
end

splits = find(test1~=1);

t1(1).b = times(1:splits(1)-1);
for i = 2:numel(splits)
    t1(i).b = times(splits(i-1)+1:splits(i)-1);
end
t1(i+1).b = times(splits(end)+1:numel(test1));

idxempties = [];
for  i = 1:numel(t1)
    if isempty(t1(i).b)
        idxempties = [idxempties i];
    end
end

t1(idxempties)=[];
%%
% want to find contiguous elements separated by less than a threshold.
% diff of times will give time between that element and the one before
% find where that diff is less than the threshold.
% 


burst_threshold = 0.2;

licks.ldiff = [NaN; diff(licks.lickTimeL)];
licks.rdiff = [NaN; diff(licks.lickTimeR)];

lb = find(diff(licks.ldiff)<0.2);
burst_starts = lb(find(diff(lb)~=1))




% subplot(211)
% histogram(licks.ldiff,100000)
% xlim([0 .5])
% subplot(212)
% histogram(licks.rdiff,100000)
% xlim([0 .5])


%%



% binning and smoothing licks
% peak of ILI is 0.1-0.2, 0.125 ish. define licks as being in a burst as
% any licks with ILI of < 0.2?
binSize = 0.1; %s
nBins = ceil(max(licks.eTime)./binSize);

[binnedLicks,~] = discretize(licks.eTime, nBins);

lickCounts = zeros(nBins, 1);

for i = 1:nBins
    lickCounts(i) = numel(find(binnedLicks==i));
end
% this gives lick counts for 100 ms bins (in bin space).


