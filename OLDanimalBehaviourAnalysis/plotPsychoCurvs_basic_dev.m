%% plot psychometric curves

activeTrialIndexes = sort([metrics.blockidx.activevary, metrics.blockidx.active]);
allActiveTrials = trial(activeTrialIndexes);

validRes = [0 1 2];
idx = ismember([allActiveTrials.response], validRes);
validTrials = allActiveTrials(idx);

ptrials = struct();

for i = 1:numel(validTrials)
    ptrials(i).delv = validTrials(i).velXR-validTrials(i).velXL;
    ptrials(i).response = validTrials(i).response;
    if (ptrials(i).response == 2) || (ptrials(i).delv > 0 && ptrials(i).response==0)
        ptrials(i).rresp = 1;
    else
        ptrials(i).rresp = 0;
    end
end

pt = struct();

speedDiffs = unique([ptrials.delv]);
for i = 1:numel(speedDiffs)
    pt(i).trials = ptrials([ptrials.delv]==speedDiffs(i));
    pt(i).nTrials = numel(pt(i).trials);
    pt(i).nR = sum([pt(i).trials.rresp]);
    pt(i).propR = pt(i).nR/pt(i).nTrials;
end

speedDiffs = fliplr(speedDiffs);
plot(speedDiffs, fliplr(propR), 'o-')

