function trial = genTrialStruct(events, params, wheel, licks)


trial = struct;
for itrial = 1:numel(events.trial.sontimes) % completed trials...
    trial(itrial).onTime = events.trial(itrial).sontimes;
    trial(itrial).stimMoveTime = events.trial(itrial).movetimes -  trial(itrial).onTime;
    trial(itrial).stimOffTime = events.trial(itrial).sofftimes - trial(itrial).onTime;
    [~, paramIdx] = findNextEvent(params.eTime, trial(itrial).onTime);
    trial(itrial).type = params.TrialType(paramIdx);
    trial(itrial).velXL = params.VelXLeft(paramIdx);
    trial(itrial).velXR = params.VelXRight(paramIdx);
    trial(itrial).geoMean = round(sqrt(trial(itrial).velXL * trial(itrial).velXR),0);
    trial(itrial).geoRatio = round(trial(itrial).velXR / trial(itrial).velXL, 2);
    trial(itrial).absRatio = trial(itrial).geoRatio;
    trial(itrial).absSD = abs(trial(itrial).velXR) - abs(trial(itrial).velXL);
    trial(itrial).response = params.Response(paramIdx);
    trial(itrial).result = params.Result(paramIdx);
    trial(itrial).rewardtime = [];
    
    % get trial block type, response window properties from event intervals
    
%     trial(itrial).block = events.blocks.tags(events.trial.sonidx(itrial)>...
%         events.blocks.intervals(:,1) & events.trial.sonidx(itrial)<events.blocks.intervals(:,2));
    trial(itrial).respSize = events.respWin.sizeTags(events.trial.sonidx(itrial)>...
        events.respWin.sizeIntervals(:,1) & events.trial.sonidx(itrial)<events.respWin.sizeIntervals(:,2));
    
    trial(itrial).respWinOpen = [];
    trial(itrial).respWinClosed = [];
    if ~isequal(trial(itrial).type,'passive')
        [~,~,~,trial(itrial).respWinOpen] = findNextEvent(events.trial.respOpentimes, trial(itrial).onTime);
        [~,~,~,trial(itrial).respWinClosed] = findNextEvent(events.trial.respClosetimes, trial(itrial).onTime);
    else % if passive, add manual response window 
        trial(itrial).respWinOpen = trial(itrial).stimMoveTime;
        trial(itrial).respWinClosed = trial(itrial).stimOffTime + 3;
    end
    
    % response == 1 i left, response == 2 is right
    % find next non-manual reward after stimonset if trial was rewarded
    if trial(itrial).result==1 %correct left
        [~,~,~,trial(itrial).rewardtime] =...
            findNextEvent(events.rewards.lrewardsTimes,trial(itrial).onTime);
    end
    if trial(itrial).result==2 %correct right
        [~,~,~,trial(itrial).rewardtime] =...
            findNextEvent(events.rewards.rrewardsTimes,trial(itrial).onTime);
    end
end

% trial licks and wheel
for itrial = 1:numel(trial)
    
    startTime = trial(itrial).onTime-1;
    stopTime = trial(itrial).onTime+trial(itrial).respWinClosed+2;
    trial(itrial).licksL = licks.lickTimeL(licks.lickTimeL < stopTime & licks.lickTimeL > startTime)-trial(itrial).onTime;
    trial(itrial).licksR = licks.lickTimeR(licks.lickTimeR < stopTime & licks.lickTimeR > startTime)-trial(itrial).onTime;
    %     itrial
    [~, wheelStartIdx] = min(abs(startTime-wheel.eTime));
    [~, wheelStopIdx] = min(abs(stopTime-wheel.eTime));
    trial(itrial).wheel = wheel.smthSpeed(wheelStartIdx:wheelStopIdx);
    
    allLicks = sort([trial(itrial).licksL; trial(itrial).licksR]);
    [~, ~, ~, trial(itrial).RT] = findNextEvent(allLicks, trial(itrial).stimMoveTime);
end

%% get average run speed

for itrial = 1:numel(trial)
    startTime = trial(itrial).onTime + trial(itrial).stimMoveTime;
    stopTime =  trial(itrial).stimOffTime;
    if trial(itrial).rewardtime < stopTime
        stopTime = trial(itrial).rewardtime;
    end
    stopTime = trial(itrial).onTime + stopTime;
    [~, wheelStartIdx] = min(abs(startTime-wheel.eTime));
    [~, wheelStopIdx] = min(abs(stopTime-wheel.eTime));
    trial(itrial).movingStimWheel = wheel.smthSpeed(wheelStartIdx:wheelStopIdx);
    trial(itrial).meanRunSpeed = nanmean(trial(itrial).movingStimWheel);
    trial(itrial).varRunSpeed = nanvar(trial(itrial).movingStimWheel);
    % classify trials as 'running', 'stationary' or mixed.
    % change so that proportion of elements (e.g. 90%) are over threshold
%     if (all(trial(itrial).movingStimWheel > 3))
%         trial(itrial).runbool = 1;
%     elseif (all(trial(itrial).movingStimWheel < 5))
%         trial(itrial).runbool = 0;
%     else
%         trial(itrial).runbool = -1;
%     end

    if sum(trial(itrial).movingStimWheel > 5) > 0.5*numel(trial(itrial).movingStimWheel)
        trial(itrial).runbool = 1;
    elseif sum(trial(itrial).movingStimWheel < 5) > 0.5*numel(trial(itrial).movingStimWheel)
        trial(itrial).runbool = 0;
    else
        trial(itrial).runbool = -1;
    end
end
    


mr = events.rewards.mrrewardsTimes;
ml = events.rewards.mlrewardsTimes;
mrews = sort([mr; ml]);
for itrial = 1:numel(trial)
    [~,~,mRewAbsTime,mRewRelTime] = findNextEvent(mrews, trial(itrial).onTime);
    if (mRewAbsTime < trial(itrial).onTime+trial(itrial).respWinClosed) & ... 
            (mRewRelTime > -2)
        trial(itrial).manualReward = 1;
        trial(itrial).manualRewardTime = mRewRelTime;
        trial(itrial).type = 'passive';
        %trial(itrial).block = 'passive';
    else
        trial(itrial).manualReward = 0;
        trial(itrial).manualRewardTime = [];
    end
    clear mRewAbsTime mRewRelTime
end

for itrial = 1:numel(trial)
    alltriallicks = sort([trial(itrial).licksL; trial(itrial).licksR]);
    % passive trials
    if isequal(trial(itrial).type, "passive")
        if any(alltriallicks > trial(itrial).respWinOpen &...
                alltriallicks < trial(itrial).rewardtime)
            trial(itrial).engaged = 1;
        else
            trial(itrial).engaged = 0;
        end
        
        %fprintf(num2str(itrial))
        %fprintf('skipping a passive trial')
        
        % not passive trials
    else
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



