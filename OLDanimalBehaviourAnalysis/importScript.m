%% import different files from behaviour
% events (trial event times)
% trial Params (parameters of each trial)
% wheel (wheel input)
% Licks (lick inputs)

folder = 'X:\ibn-vision\DATA\SUBJECTS\M19027\Training\20190606'

[events, params, wheel, licks] = importSessionFiles(folder);

% %% Events
% filePattern = fullfile(folder, 'Events*.*');
% fileList = dir(filePattern);
% if numel(fileList)>1, error('multiple event files detected'), end
% eventsFileName = [fileList.folder, '\' fileList.name]
% [events.tags,events.ts] = importEventsFile(eventsFileName);
% 
% %% Trial Params
% filePattern = fullfile(folder, 'TrialParams*.*');
% fileList = dir(filePattern);
% if numel(fileList)>1, error('multiple trial param files detected'), end
% paramsFileName = [fileList.folder, '\' fileList.name]
% 
% [params.trialID,params.trialDuration,params.dotSize,params.dotCol1,...
%     params.dotCol2,params.numDots1,params.numDots2,params.dotLifeBool,...
%     params.dotLifetime,params.contrast,params.velXLeft,params.velYLeft,...
%     params.cohLeft,params.velXRight,params.velYRight,params.cohRight,...
%     params.response,params.ts] = importParamsFile(paramsFileName, 2, inf);
% 
% %% Wheel
% filePattern = fullfile(folder, 'Wheel*.*');
% fileList = dir(filePattern);
% if numel(fileList)>1, error('multiple wheel files detected'), end
% wheelFileName = [fileList.folder, '\' fileList.name]
% 
% [wheel.pos,wheel.ts] = importWheelFile(wheelFileName);
% 
% % below needs fixing: use elapsed time, and convert to cm
% wheel.pos(1) = wheel.pos(2); 
% 
% %% Licks
% filePattern = fullfile(folder, 'Lick*.*');
% fileList = dir(filePattern);
% if numel(fileList)>1, error('multiple lick files detected'), end
% licksFileName = [fileList.folder, '\' fileList.name]
% 
% [licks.leftLicks,licks.rightLicks,licks.ts] = importLicksFile(licksFileName, 2, inf);

% 
% %% convert datetimes to datenum and elapsed time
% events.eTime = datenum(events.ts)*86400;
% params.eTime = datenum(params.ts)*86400;
% wheel.eTime = datenum(wheel.ts)*86400;
% licks.eTime = datenum(licks.ts)*86400;
% 
% referenceTime = wheel.eTime(1);
% 
% events.eTime = events.eTime - referenceTime;
% params.eTime = params.eTime - referenceTime;
% wheel.eTime = wheel.eTime - referenceTime;
% licks.eTime = licks.eTime - referenceTime;

%% get wheel speed
idx = find(isnan(wheel.eTime));

for i = 1:numel(idx) % interpolate any NaNs in elapsed time
    wheel.eTime(idx) = (wheel.eTime(idx-1) + wheel.eTime(idx+1) ) /2;
end

halfMax = max(wheel.pos)/2;
wheel.unwrapped = unwrap(wheel.pos, halfMax);
% not sure I have the right ticks per rev.
wheel.dist = wheel2unit(wheel.unwrapped, 1024, 17.78); % pos, ticks/rev, wheel diam

% this doesnt seem right? need to do movmw
wheel.rawSpeed = diff(wheel.dist)./diff(wheel.eTime);
wheel.rawSpeed = movmean(wheel.rawSpeed, 2);
wheel.rawSpeed = [wheel.rawSpeed(1); wheel.rawSpeed];
wheel.smthSpeed = smoothdata(wheel.rawSpeed,'gaussian',20);
plot(wheel.eTime(1:1000), wheel.smthSpeed(1:1000))

 temp_speed = diff(wheel.pos);
 wheel.speed = movmean(temp_speed, 2);
% wheel.speed = [wheel.speed(1); wheel.speed];
% temp_acc = diff(wheel.speed);
% wheel.acc = movmean(temp_acc, 2);
% wheel.acc = [wheel.acc(1); wheel.acc];


%% Generate trials struct
% TO DO: need to deal with if there was an extra trial added which wasn't
% completed

% find in elapsed time, the times of events related to each trial

events.sonidx = find(events.tags=="stimON");
events.moveidx = find(events.tags=="dotsMOVE");
events.soffidx = find(events.tags=="stimOFF");

if numel(events.soffidx) < numel(events.sonidx)
    events.sonidx = events.sonidx(1:numel(events.soffidx));
    events.moveidx = events.moveidx(1:numel(events.soffidx));
    events.soffidx = events.soffidx(1:numel(events.soffidx));
end

events.sontimes = events.eTime(events.sonidx); % need to temp fix this for broken logging...just say movetime - 1;
events.movetimes = events.eTime(events.moveidx);
events.sofftimes = events.eTime(events.soffidx);
events.sontimes = events.movetimes - 1; % comment out when fixed. %%%%%%%%%%%%%%%%

events.rewardsidx = find(contains(events.tags, 'r') | contains(events.tags, 'l'));
events.rewardtimes = events.eTime(events.rewardsidx);
events.rewardstags = events.tags(events.rewardsidx);

% generate a trial struct, with trial-centric information 
trial = struct;
for itrial = 1:numel(events.sontimes) % completed trials...
    trial(itrial).onTime = events.sontimes(itrial);
    trial(itrial).stimMoveTime = events.movetimes(itrial) -  trial(itrial).onTime;
    trial(itrial).stimOffTime = events.sofftimes(itrial) - trial(itrial).onTime;
    trial(itrial).velXL = params.velXLeft(itrial);
    trial(itrial).velXR = params.velXRight(itrial);
    trial(itrial).response = params.response(itrial);
    % reward times (deals with manually given rewards which corrupt)
    [~, rewardidx] = min(abs(events.sofftimes(itrial) - events.rewardtimes));
    trial(itrial).rewardTime = events.rewardtimes(rewardidx) - trial(itrial).onTime;
    trial(itrial).rewardTag = events.rewardstags(rewardidx);
end


%% trial-centric licking and running
leftidx = 1 + find(diff(licks.leftLicks)==1);
rightidx = 1 + find(diff(licks.rightLicks)==1);
events.lickTimeL =  licks.eTime(leftidx);
events.lickTimeR =  licks.eTime(rightidx);

for itrial = 1:numel(events.sofftimes)
    % get time interval from ontime -1 to offtime + 2
    startTime = trial(itrial).onTime-1;
    stopTime = trial(itrial).onTime+trial(itrial).stimOffTime+2; %2s after the stimulus is off...
    trial(itrial).licksL = events.lickTimeL(events.lickTimeL < stopTime & events.lickTimeL > startTime)-trial(itrial).onTime;
    trial(itrial).licksR = events.lickTimeR(events.lickTimeR < stopTime & events.lickTimeR > startTime)-trial(itrial).onTime;
    
    [~, wheelStartIdx] = min(abs(startTime-wheel.eTime));
    [~, wheelStopIdx] = min(abs(stopTime-wheel.eTime));
    trial(itrial).wheel = wheel.speed(wheelStartIdx:wheelStopIdx);
    
end


%% When are mice licking?
% need to define time periods of different epochs.
respWindowLength = 2;

epochs.stimOnNotMoving = [];
epochs.stimOnMoving = [];
epochs.respWindow = [];
epochs.ISI = [];

for itrial = 1:numel(events.sontimes)-1
    epochs.stimOnNotMoving = [epochs.stimOnNotMoving; trial(itrial).onTime, events.movetimes(itrial)];
    epochs.stimOnMoving = [epochs.stimOnMoving; events.movetimes(itrial), events.sofftimes(itrial)];
    epochs.respWindow = [epochs.respWindow; events.sofftimes(itrial), events.sofftimes(itrial)+respWindowLength]; % not meaningful for passive?
    epochs.ISI = [epochs.ISI; events.sofftimes(itrial)+2, trial(itrial+1).onTime];
end

% number of licks in:
% stim on not moving

licks = struct;
B1 = epochs.stimOnNotMoving;
B2 = epochs.stimOnMoving;
B3 = epochs.respWindow;
B4 = epochs.ISI;

% left licks
idx1 = false(size(events.lickTimeL));
idx2 = false(size(events.lickTimeL));
idx3 = false(size(events.lickTimeL));
idx4 = false(size(events.lickTimeL));

for ii = 1:length(events.lickTimeL)
  idx1(ii) = any((events.lickTimeL(ii)>B1(:,1))&(events.lickTimeL(ii)<B1(:,2)));
  idx2(ii) = any((events.lickTimeL(ii)>B2(:,1))&(events.lickTimeL(ii)<B2(:,2)));
  idx3(ii) = any((events.lickTimeL(ii)>B3(:,1))&(events.lickTimeL(ii)<B3(:,2)));
  idx4(ii) = any((events.lickTimeL(ii)>B4(:,1))&(events.lickTimeL(ii)<B4(:,2)));
end

licks.totals.stimOnNotMoving(1) = sum(idx1);
licks.totals.stimOnMoving(1) = sum(idx2);
licks.totals.respWindow(1) = sum(idx3);
licks.totals.ISI(1) = sum(idx4);

clear idx1 idx2 idx3 idx4

% right licks

% left licks
idx1 = false(size(events.lickTimeR));
idx2 = false(size(events.lickTimeR));
idx3 = false(size(events.lickTimeR));
idx4 = false(size(events.lickTimeR));

for ii = 1:length(events.lickTimeR)
  idx1(ii) = any((events.lickTimeR(ii)>B1(:,1))&(events.lickTimeR(ii)<B1(:,2)));
  idx2(ii) = any((events.lickTimeR(ii)>B2(:,1))&(events.lickTimeR(ii)<B2(:,2)));
  idx3(ii) = any((events.lickTimeR(ii)>B3(:,1))&(events.lickTimeR(ii)<B3(:,2)));
  idx4(ii) = any((events.lickTimeR(ii)>B4(:,1))&(events.lickTimeR(ii)<B4(:,2)));
end

licks.totals.stimOnNotMoving(2) = sum(idx1);
licks.totals.stimOnMoving(2) = sum(idx2);
licks.totals.respWindow(2) = sum(idx3);
licks.totals.ISI(2) = sum(idx4);

clear idx1 idx2 idx3 idx4

% lick frequency (#licks/time in epoch)

licks.freqs.stimOnNotMoving = sum(licks.totals.stimOnNotMoving)/sum(B1(:,2)-B1(:,1));
licks.freqs.stimOnMoving = sum(licks.totals.stimOnMoving)/sum(B2(:,2)-B2(:,1));
licks.freqs.respWindow = sum(licks.totals.respWindow)/sum(B3(:,2)-B3(:,1));
licks.freqs.ISI = sum(licks.totals.ISI)/sum(B4(:,2)-B4(:,1));

figure
hb = bar([licks.freqs.stimOnNotMoving, licks.freqs.stimOnMoving, licks.freqs.respWindow, licks.freqs.ISI], 'FaceColor','flat')
ylabel('mean lick frequency (Hz)')
a = gca
a.XTickLabel = [{'stat stim'}, {'moving stim'}, {'resp window'}, {'ISI'}];
hb.CData = [.8 .8 .8; .6 .6 .6; .4 .4 .4; .2 .2 .2]
box off
%a.XTickLabelRotation = 45
% want to check -> pre-emptive licks correct or not?

%% plot all trials in one figure

lefttrials = []; righttrials =[];
for itrial = 1:numel(trial)
    if trial(itrial).velXL < trial(itrial).velXR
        lefttrials = [lefttrials; itrial];
    else
        righttrials = [righttrials; itrial];
    end
end

trialCounter = 0;
figure, hold on,
for ileft = 1:numel(lefttrials)
    trialCounter = trialCounter + 1;
    p = plot(trial(lefttrials(ileft)).licksL, repelem(trialCounter, 1, numel(trial(lefttrials(ileft)).licksL)), 'b*');
    p2= plot(trial(lefttrials(ileft)).licksR, repelem(trialCounter, 1, numel(trial(lefttrials(ileft)).licksR)), 'r*');
end
plot(-1:4, repelem(trialCounter + 0.5, 6, 1), 'k--')

for iright = 1:numel(righttrials)
    trialCounter = trialCounter + 1;
    plot(trial(righttrials(iright)).licksL, repelem(trialCounter, 1, numel(trial(righttrials(iright)).licksL)), 'b*')
    plot(trial(righttrials(iright)).licksR, repelem(trialCounter, 1, numel(trial(righttrials(iright)).licksR)), 'r*')
end

plot([-1 0 0 2 2 3 4],  [trialCounter+12 trialCounter+12 trialCounter+22 trialCounter+22 trialCounter+12 trialCounter+12 trialCounter+12], 'k-', 'LineWidth', 3)
plot([-1 1 1 2 2 3 4], [trialCounter+1 trialCounter+1 trialCounter+11 trialCounter+11 trialCounter+1 trialCounter+1 trialCounter+1], 'k--', 'LineWidth', 3)
plot([0 0], [0 trialCounter+12], 'k-.')
plot([1 1], [0 trialCounter+12], 'k-.')
plot([2 2], [0 trialCounter+12], 'k-.')

xlabel('trial time (s)'); xlim([-1 4])
ylabel('<--Right Trials      Left Trials-->', 'FontSize', 18);
a = gca;
a.YTick = []



% plot individual trials

figure
for itrial = 1:numel(trial)

plot([-1 0 0 trial(itrial).stimOffTime trial(itrial).stimOffTime trial(itrial).stimOffTime+8],  [9 9 10 10 9 9], 'k-')
hold on
if trial(itrial).velXR < trial(itrial).velXL
    linetag = 'r-';
else linetag = 'b-';
end
plot([-1 trial(itrial).stimMoveTime trial(itrial).stimMoveTime trial(itrial).stimOffTime trial(itrial).stimOffTime trial(itrial).stimOffTime+8],  [8 8 8.9 8.9 8 8], linetag)

if contains(trial(itrial).rewardTag, 'l')
    linetag = 'b--';
elseif contains(trial(itrial).rewardTag, 'r')
    linetag = 'r--';
end
plot([-1 trial(itrial).rewardTime, trial(itrial).rewardTime, trial(itrial).rewardTime+0.1 trial(itrial).rewardTime+0.1 trial(itrial).stimOffTime+8],...
    [7 7 7.9 7.9 7 7],linetag)

plot(trial(itrial).licksL, 6.5*ones(size(trial(itrial).licksL)), 'b*')
plot(trial(itrial).licksR, 6*ones(size(trial(itrial).licksR)), 'r*')
ylim([5.5 10.5])
xlim([-1 8])
hold off
pause
end