events.activeTrialStarts = find(events.tags=="active");
events.passiveTrialStarts = find(events.tags=="passive");


% now all stimON tags between these are passive.
% need to do based on whichever trial type came first?

for ipass = 1:numel(events.passiveTrialStarts)
    pinterval(ipass,1) = events.passiveTrialStarts(ipass);
    laterActives = find(events.activeTrialStarts > events.passiveTrialStarts(ipass));
    try
        pinterval(ipass,2) = events.activeTrialStarts(laterActives(1));
    catch
        pinterval(ipass,2) = inf;
    end
end


idx = false(size(A));
for ii = 1:length(A)
  idx(ii) = any((A(ii)>B(:,1))&(A(ii)<B(:,2)));
end