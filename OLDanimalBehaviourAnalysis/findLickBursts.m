function burstsStruct = findLickBursts(times, threshold)

% more elegant solution?

test1 = diff(times)<threshold;
if times(2)-times(1) < threshold
    test1 = [1; test1];
else
    test1 = [0; test1];
end

splits = find(test1~=1);

t1(1).b = times(1:splits(1)-1);
for i = 2:numel(splits)
    t1(i).b = times(splits(i-1):splits(i)-1);
end
t1(i+1).b = times(splits(end):numel(test1));

idxempties = []; % find any bursts that are empty or have just 1 lick
% relabel as single licks, not bursts
for  i = 1:numel(t1)
    if isempty(t1(i).b) || numel(t1(i).b)<2
        idxempties = [idxempties i];
        
    end
end

t1(idxempties)=[];

burstsStruct = t1;