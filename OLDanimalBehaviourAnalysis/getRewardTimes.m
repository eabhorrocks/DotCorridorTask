function events = getRewardTimes(events)

events.rewards.rrewardsidx = [];
events.rewards.lrewardsidx = [];
events.rewards.mrrewardsidx = [];
events.rewards.mlrewardsidx = [];

% right rewards (trial and manual)
% create a cell array of size(events.tags) with 0x0 string where there is
% no match to 'r' followed by a double.
temp = regexp(events.tags,'r[\d*]','Match'); 
for i = 1:numel(temp)
    if ~isempty(temp{i}) % check if not empty
        if contains(events.tags(i),'m') % check if this tag contains an m (manual reward)
            events.rewards.mrrewardsidx(end+1,:) = i; % add this idx to manual
        else
            events.rewards.rrewardsidx(end+1,:) = i; % add this idx to trial rewards
        end
    end
end

temp = regexp(events.tags,'l[\d*]','Match'); 
for i = 1:numel(temp)
    if ~isempty(temp{i}) % check if not empty
        if contains(events.tags(i),'m') % check if this tag contains an m (manual reward)
            events.rewards.mlrewardsidx(end+1,:) = i; % add this idx to manual
        else
            events.rewards.lrewardsidx(end+1,:) = i; % add this idx to trial rewards
        end
    end
end

events.rewards.rrewardsTimes = events.eTime(events.rewards.rrewardsidx);
events.rewards.mrrewardsTimes = events.eTime(events.rewards.mrrewardsidx);
events.rewards.lrewardsTimes = events.eTime(events.rewards.lrewardsidx);
events.rewards.mlrewardsTimes = events.eTime(events.rewards.mlrewardsidx);


end
