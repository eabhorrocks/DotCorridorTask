function trial = genTrialStruct(events_tbl, licks_tbl, trialParams_tbl, wheel_tbl, timeStamp2Use)

% takes events_tbl and licks_tbl (directly imported using readtable) as
% inputs and returns events and licks structs with information for
% generating trial struct array

% events_tbl = session(1).events_tbl;
% licks_tbl = session(1).lick_tbl;

%% determine trial index of events

nCompletedTrials =  numel(find(events_tbl.Event=="dotsMOVE"));
nAbortedTrials = numel(find(events_tbl.Event=="stimON"))-nCompletedTrials; % this may be fixed in new Bonsai workflows

% these events ALWAYS happen if a trial is not aborted.
dotsMoveIdx=find(events_tbl.Event=="dotsMOVE");
respOpenIdx=find(events_tbl.Event=="respOPEN");
respCloseIdx = find(events_tbl.Event=="respCLOSED");

for itrial = 1:nCompletedTrials
    % indexes
    events.trial(itrial).moveidx = dotsMoveIdx(itrial);
    events.trial(itrial).sonidx = find(events_tbl.Event(1:dotsMoveIdx(itrial))=="stimON",1,'last'); % most recent "stimON"
    events.trial(itrial).soffidx =...
        find(events_tbl.Event(dotsMoveIdx(itrial):end)=="stimOFF",1,'first') +  dotsMoveIdx(itrial) -1; % next "stimOFF"
    events.trial(itrial).respOpenidx = respOpenIdx(itrial);
    events.trial(itrial).respCloseidx = respCloseIdx(itrial);

    % timestamps
    events.trial(itrial).sontimes = events_tbl.(timeStamp2Use)(events.trial(itrial).sonidx);
    events.trial(itrial).movetimes = events_tbl.(timeStamp2Use)(events.trial(itrial).moveidx);
    events.trial(itrial).sofftimes = events_tbl.(timeStamp2Use)(events.trial(itrial).soffidx);
    events.trial(itrial).respOpentimes = events_tbl.(timeStamp2Use)(events.trial(itrial).respOpenidx);
    events.trial(itrial).respClosetimes = events_tbl.(timeStamp2Use)(events.trial(itrial).respCloseidx);

end


%% get reward times using regexp, invariant to the valve opening times.
events.rewards = getRewardTimes(events_tbl,timeStamp2Use);

%% get times of left and right licks

% check for increment of lick counter
leftidx = 1 + find(diff(licks_tbl.LeftLick)==1);
rightidx = 1 + find(diff(licks_tbl.RightLick)==1);

% add index for first lick (either left or right)
if licks_tbl.LeftLick(1)==1
    leftidx = [1; leftidx];
end
if licks_tbl.RightLick(1)==1
    rightidx = [1; rightidx];
end

licks.lickTimeL =  licks_tbl.(timeStamp2Use)(leftidx);
licks.lickTimeR =  licks_tbl.(timeStamp2Use)(rightidx);

%% get intervals of different response window periods
tags = {'respDelay'};
[events.respWin.delayIntervals, events.respWin.delayTags, ~] =...
    findIntervals(events_tbl.Event, tags, 'contains');

tags = {'respSize'};
[events.respWin.sizeIntervals, events.respWin.sizeTags, ~] =...
    findIntervals(events_tbl.Event, tags, 'contains');


%% generate trial struct

% check trial params and processed events have equal number of trials
if numel(events.trial)~=height(trialParams_tbl)
    error('different number of trials detected from event markers and trial params table')
end

trial = struct;
for itrial = 1:height(trialParams_tbl) % completed trials...
    % trial centric stimulus event times
    trial(itrial).onTime = events.trial(itrial).sontimes;
    trial(itrial).stimMoveTime = events.trial(itrial).movetimes -  trial(itrial).onTime;
    trial(itrial).stimOffTime = events.trial(itrial).sofftimes - trial(itrial).onTime;

    % get index of trial params (currently just using itrial)
    %[~, paramIdx] = findNextEvent(trialParams_tbl.(timeStamp2Use), trial(itrial).onTime);

    trial(itrial).type = trialParams_tbl.TrialType(itrial);
    trial(itrial).LeftVel = trialParams_tbl.LeftVel(itrial);
    trial(itrial).RightVel = trialParams_tbl.RightVel(itrial);
    trial(itrial).geoMean = round(sqrt(trial(itrial).LeftVel * trial(itrial).RightVel),0);
    trial(itrial).absSpeedRatio = 2.^abs(log2((trial(itrial).RightVel/trial(itrial).LeftVel)));
    trial(itrial).speedRatio = trial(itrial).RightVel/trial(itrial).LeftVel;

    %trial(itrial).geoRatio = round(trial(itrial).velXR / trial(itrial).velXL, 2);
    %trial(itrial).absRatio = trial(itrial).geoRatio;
    trial(itrial).absSD = abs(trial(itrial).LeftVel) - abs(trial(itrial).RightVel);
    trial(itrial).response = trialParams_tbl.Response(itrial);
    trial(itrial).result = trialParams_tbl.TrialResult(itrial);
    trial(itrial).rewardtime = nan;

    % get trial response window properties from event intervals
    trial(itrial).respSize = events.respWin.sizeTags(events.trial(itrial).sonidx>...
        events.respWin.sizeIntervals(:,1) & events.trial(itrial).sonidx<events.respWin.sizeIntervals(:,2));
    trial(itrial).respSize = str2double(extract(trial(itrial).respSize, digitsPattern))*1000; % extract number and convert to ms

    trial(itrial).respWinOpen =nan;
    trial(itrial).respWinClosed =nan;

    [~,~,~,trial(itrial).respWinOpen] = findNextEvent([events.trial.respOpentimes], trial(itrial).onTime);
    [~,~,~,trial(itrial).respWinClosed] = findNextEvent([events.trial.respClosetimes], trial(itrial).onTime);


    % response == -1 i left, response == 2 is right
    % find next non-manual reward after stimonset if trial was rewarded
    if trial(itrial).result==-1 %correct left
        [~,~,~,trial(itrial).rewardtime] =...
            findNextEvent(events.rewards.lrewardsTimes,trial(itrial).onTime);
    end
    if trial(itrial).result==1 %correct right
        [~,~,~,trial(itrial).rewardtime] =...
            findNextEvent(events.rewards.rrewardsTimes,trial(itrial).onTime);
    end
end


%% trial licks and wheel

for itrial = 1:numel(trial)
    startTime = trial(itrial).onTime-1000;
    stopTime = startTime+trial(itrial).respWinOpen+trial(itrial).respSize+2000;

    trial(itrial).licksL = licks.lickTimeL(licks.lickTimeL < stopTime & licks.lickTimeL > startTime)-trial(itrial).onTime;
    trial(itrial).licksR = licks.lickTimeR(licks.lickTimeR < stopTime & licks.lickTimeR > startTime)-trial(itrial).onTime;

    trial(itrial).firstLick=nan;
    if ~isempty([trial(itrial).licksL]) && isempty([trial(itrial).licksR])
        trial(itrial).firstLick = -1;
    elseif isempty([trial(itrial).licksL]) && ~isempty([trial(itrial).licksR])
         trial(itrial).firstLick = 1;
    elseif ~isempty([trial(itrial).licksL]) && ~isempty([trial(itrial).licksR])
        if min([trial(itrial).licksL])<min([trial(itrial).licksR])
                    trial(itrial).firstLick = -1;
        elseif min([trial(itrial).licksR])>min([trial(itrial).licksL])
                    trial(itrial).firstLick = 1;
        end
    end
        trial(itrial).correct = sign( trial(itrial).firstLick * sign(trial(itrial).speedRatio-1))>0;

    %     wheel
    [~, wheelStartIdx] = min(abs(startTime-wheel_tbl.(timeStamp2Use)));
    [~, wheelStopIdx] = min(abs(stopTime-wheel_tbl.(timeStamp2Use)));
    trial(itrial).wheel = wheel_tbl.Speed(wheelStartIdx:wheelStopIdx);
    trial(itrial).wheelTime = wheel_tbl.(timeStamp2Use)(wheelStartIdx:wheelStopIdx)-trial(itrial).onTime;

    allLicks = sort([trial(itrial).licksL; trial(itrial).licksR]);
    [~, ~, ~, trial(itrial).RT] = findNextEvent(allLicks, trial(itrial).stimMoveTime);

    if isempty(trial(itrial).RT), trial(itrial).RT=nan; end

end


%% get average run speed

% run speed for stimulus onset to stimulus offset/RT
for itrial = 1:numel(trial)
    startTime = trial(itrial).onTime + trial(itrial).stimMoveTime;
    stopTime =  trial(itrial).stimOffTime;
    if trial(itrial).rewardtime < stopTime
        stopTime = trial(itrial).rewardtime;
    end
    stopTime = trial(itrial).onTime + stopTime;
    [~, wheelStartIdx] = min(abs(startTime-wheel_tbl.(timeStamp2Use)));
    [~, wheelStopIdx] = min(abs(stopTime-wheel_tbl.(timeStamp2Use)));
    trial(itrial).runSpeedtoRT = wheel_tbl.Speed(wheelStartIdx:wheelStopIdx);
    trial(itrial).meanRunSpeedtoRT = mean(trial(itrial).runSpeedtoRT);
end


%% process manual rewards for trials
try
mr = events.rewards.mrrewardsTimes;
ml = events.rewards.mlrewardsTimes;
mrews = sort([mr; ml]);
for itrial = 1:numel(trial)
    % default is no manual reward
    trial(itrial).manualReward = 0;
    trial(itrial).manualRewardTime = nan;
    [~,~,mRewAbsTime,mRewRelTime] = findNextEvent(mrews, trial(itrial).onTime);
    
    if ~isempty(mRewAbsTime) % if there is a manual reward 
    if (mRewAbsTime < trial(itrial).onTime+trial(itrial).respWinClosed) && ...
            (mRewRelTime > -2000) % if it happens before resp win closed
        trial(itrial).manualReward = 1;
        trial(itrial).manualRewardTime = mRewRelTime;
        trial(itrial).type=0; % manual
    end
    end
    clear mRewAbsTime mRewRelTime
end
catch
debug=1;
end

%% 
for itrial = 1:numel(trial)
    alltriallicks = sort([trial(itrial).licksL; trial(itrial).licksR]);
    % if passive trials
    if trial(itrial).type==1 || trial(itrial).manualReward==1 % passsive trials
        if any(alltriallicks > trial(itrial).respWinOpen &...
                alltriallicks < trial(itrial).respWinClosed)
            trial(itrial).engaged = 1; % specific definition of engaged for passive trials
        else
            trial(itrial).engaged = 0;
        end
    else % not passive trials
        if (trial(itrial).response ~=0 && trial(itrial).manualReward==0)
            trial(itrial).engaged = 1;
        elseif (any(alltriallicks > trial(itrial).respWinOpen &...
                alltriallicks < trial(itrial).respWinClosed)) && (trial(itrial).manualReward==0)
            trial(itrial).engaged = 1;
        else
            trial(itrial).engaged = 0;
        end
    end
end


