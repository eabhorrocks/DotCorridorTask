function [events, licks] = processEvents(events, licks, blockTags)

% deal with weird bonsai issue where stimON might be logged but trial not
% complete
% todel = [];
% for i=1:numel(events.tags)-1
%     if strcmp(events.tags(i), "stimON")
%         if any(strcmp(events.tags(i+1), blockTags))
%             todel = [todel, i];
%         end
%     end
% end

%events.tags(todel) = [];

nstimON = numel(find(events.tags=="stimON"));
ndotsMOVE = numel(find(events.tags=="dotsMOVE"));
nstimOFF = numel(find(events.tags=="stimOFF"));
nrespOPEN = numel(find(events.tags=="respOPEN"));
nrespCLOSED = numel(find(events.tags=="respCLOSED"));

nTrialEvents = [nstimON, ndotsMOVE, nstimOFF];
% if numel(unique(nTrialEvents)~=1)
%     error('different number of trial event tags found')
% end
% 
% nRespEvents = [nrespOPEN, nrespCLOSED];
% if numel(unique(nRespEvents)~=1)
%     error('different number of response window event tags found')
% end

events.trial.sonidx = find(events.tags=="stimON");
events.trial.moveidx = find(events.tags=="dotsMOVE");
events.trial.soffidx = find(events.tags=="stimOFF");
events.trial.respOpenidx = find(events.tags=="respOPEN");
events.trial.respCloseidx = find(events.tags=="respCLOSED");


% for itrial = 1:nstimON % find next event tags with > index
%     if ~(events.trial.sonidx(itrial) < events.trial.moveidx(itrial) < ...
%             events.trial.soffidx(itrial))
%     warning(['trial events are not in correct order for trial: ' num2str(itrial)])
%     end
% end
% 
% for itrial = 1:nrespOPEN
%     if ~(events.trial.respOpenidx(itrial) < events.trial.respCloseidx(itrial))
%         warning(['response window events are not in correct order for trial: ' num2str(itrial)])
%     end
% end
    
    
% check for incomplete trials and delete tags from them
if numel(events.trial.soffidx) < numel(events.trial.sonidx)
     events.trial.sonidx = events.trial.sonidx(1:numel(events.trial.soffidx));
     events.trial.moveidx = events.trial.moveidx(1:numel(events.trial.soffidx));
     events.trial.soffidx = events.trial.soffidx(1:numel(events.trial.soffidx));
end



events.trial.sontimes = events.eTime(events.trial.sonidx); 
events.trial.movetimes = events.eTime(events.trial.moveidx);
events.trial.sofftimes = events.eTime(events.trial.soffidx);
events.trial.respOpentimes = events.eTime(events.trial.respOpenidx);
events.trial.respClosetimes = events.eTime(events.trial.respCloseidx);

% get reward times using regexp, invariant to the valve opening times.
events = getRewardTimes(events);

% get times of left and right licks
leftidx = 1 + find(diff(licks.leftLicks)==1);
rightidx = 1 + find(diff(licks.rightLicks)==1);
licks.lickTimeL =  licks.eTime(leftidx);
licks.lickTimeR =  licks.eTime(rightidx);


% get intervals of different 
tags = {'respDelay'};
[events.respWin.delayIntervals, events.respWin.delayTags, ~] =...
    findIntervals(events.tags, tags, 'contains');

tags = {'respSize'};
[events.respWin.sizeIntervals, events.respWin.sizeTags, ~] =...
    findIntervals(events.tags, tags, 'contains');
