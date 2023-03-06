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

%% get indexes and time stamps fo basic trial events
% nstimON = numel(find(events.tags=="stimON"));
% ndotsMOVE = numel(find(events.tags=="dotsMOVE"));
% nstimOFF = numel(find(events.tags=="stimOFF"));
% nrespOPEN = numel(find(events.tags=="respOPEN"));
% nrespCLOSED = numel(find(events.tags=="respCLOSED"));

% complete trials have 'dotsMOVE' - after that point the trial is never
% aborted
% Therefore, find 'dotsMOVE' indexes, then find the most recent stimON (and check
% timing is ~0.5?). Then also find the next stimOFF, resp window etc.
nCompletedTrials =  numel(find(events.tags=="dotsMOVE"));
nAbortedTrials = numel(find(events.tags=="stimON"))-nCompletedTrials-1; % always 1 extra "stimON";

% these events ALWAYS happen if a trial is not aborted.
dotsMoveIdx=find(events.tags=="dotsMOVE");
respOpenIdx=find(events.tags=="respOPEN");
respCloseIdx = find(events.tags=="respCLOSED");

for itrial = 1:nCompletedTrials
    % indexes
    events.trial(itrial).moveidx = dotsMoveIdx(itrial);
    events.trial(itrial).sonidx = find(events.tags(1:dotsMoveIdx(itrial))=="stimON",1,'last'); % most recent "stimON"
    events.trial(itrial).soffidx =...
        find(events.tags(dotsMoveIdx(itrial):end)=="stimOFF",1,'first') +  dotsMoveIdx(itrial) -1; % next "stimOFF"
    events.trial(itrial).respOpenidx = respOpenIdx(itrial);
    events.trial(itrial).respCloseidx = respCloseIdx(itrial);

    % timestamps
    events.trial(itrial).sontimes = events.eTime(events.trial(itrial).sonidx); 
    events.trial(itrial).movetimes = events.eTime(events.trial(itrial).moveidx);
    events.trial(itrial).sofftimes = events.eTime(events.trial(itrial).soffidx);
    events.trial(itrial).respOpentimes = events.eTime(events.trial(itrial).respOpenidx);
    events.trial(itrial).respClosetimes = events.eTime(events.trial(itrial).respCloseidx);

end

% nTrialEvents = [nstimON, ndotsMOVE, nstimOFF];
% if numel(unique(nTrialEvents)~=1)
%     error('different number of trial event tags found')
% end
% 
% nRespEvents = [nrespOPEN, nrespCLOSED];
% if numel(unique(nRespEvents)~=1)
%     error('different number of response window event tags found')
% end

% events.trial.sonidx = find(events.tags=="stimON");
% events.trial.moveidx = find(events.tags=="dotsMOVE");
% events.trial.soffidx = find(events.tags=="stimOFF");
% events.trial.respOpenidx = find(events.tags=="respOPEN");
% events.trial.respCloseidx = find(events.tags=="respCLOSED");


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
    
% complete trials have 'DOTS MOVE', after that point, the trial is never
% aborted
% SO: find 'DOTS MOVE' indexes, then find the most recent stimON (and check
% timing is ~0.5 ?). Then also find the next stimOFF, resp window etc.
    
% check for incomplete trials and delete tags from them
% if numel(events.trial.soffidx) < numel(events.trial.sonidx)
%      events.trial.sonidx = events.trial.sonidx(1:numel(events.trial.soffidx));
%      events.trial.moveidx = events.trial.moveidx(1:numel(events.trial.soffidx));
%      events.trial.soffidx = events.trial.soffidx(1:numel(events.trial.soffidx));
% end

%% get the times corresponding to the event indexes
% events.trial.sontimes = deal(events.eTime(events.trial.sonidx)); 
% events.trial.movetimes = events.eTime(events.trial.moveidx);
% events.trial.sofftimes = events.eTime(events.trial.soffidx);
% events.trial.respOpentimes = events.eTime(events.trial.respOpenidx);
% events.trial.respClosetimes = events.eTime(events.trial.respCloseidx);

%% get reward times using regexp, invariant to the valve opening times.
events = getRewardTimes(events);

%% get times of left and right licks
leftidx = 1 + find(diff(licks.leftLicks)==1);
rightidx = 1 + find(diff(licks.rightLicks)==1);
licks.lickTimeL =  licks.eTime(leftidx);
licks.lickTimeR =  licks.eTime(rightidx);


%% get intervals of different response window periods
tags = {'respDelay'};
[events.respWin.delayIntervals, events.respWin.delayTags, ~] =...
    findIntervals(events.tags, tags, 'contains');

tags = {'respSize'};
[events.respWin.sizeIntervals, events.respWin.sizeTags, ~] =...
    findIntervals(events.tags, tags, 'contains');
