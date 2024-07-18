%% Speed discrimination training session analysis (DEVELOPMENT)
clc, clear % necessary for now

addpath(genpath('C:\Users\edward.horrocks\Documents\Code\GenericFunctions'));
addpath(genpath('C:\Users\edward.horrocks\Documents\Code\AnimalBehaviouralTasks\DotCorridorTask\BehaviourAnalysis'));


serverDir='Z:\ibn-vision\DATA\SUBJECTS\';
timeStamp2Use = 'ArduinoTime'; % 'ArduinoTime', 'BonsaiTime', [in any case should be ms] ?{or 'SyncPulse'}

%% Session details
Subject = 'M24020';
Session = '20240503';

sessionDir = fullfile(serverDir, Subject, 'Training', Session);

%% import session files 

session = importSDSessionFiles(sessionDir);
nSessions = numel(session);

%% process wheel data to unwrap and get speed
wheelDiamater = 19; % clear wheel 

for isession = 1:nSessions
    session(isession).wheel_tbl = processWheelTable_SD(session(isession).wheel_tbl, ...
        wheelDiamater, timeStamp2Use);
end
%% generate trial struct
for isession = 1:nSessions

    [session(isession).trials] = ...
    genTrialStruct(session(isession).events_tbl, session(isession).lick_tbl,...
    session(isession).trialParams_tbl, session(isession).wheel_tbl, timeStamp2Use);


end

%% get basic session metrics

%% n trials
allTrials = cat(2,session.trials);

% number of trial types presented
nTrials = histcounts([allTrials.type], 'BinEdges',-0.5:4.5);

% number engaged with and correct
for itrialtype = 1:5
    tempTrials = allTrials([allTrials.type]==itrialtype-1);
    nEngaged(itrialtype)=sum([tempTrials.engaged]);
    engagedTrials = tempTrials([tempTrials.engaged]==1);
    nCorrect(itrialtype) = sum([engagedTrials.correct]);
end

% overlay plots
figure
subplot(311), hold on
bar(1:5, nTrials)
bar(1:5, nEngaged)
bar(1:5, nCorrect)
ax = gca; ax.XTick = 1:5; 
ax.XTickLabel = {'manual', 'passive','active-any','active-noabort','active'};
ylabel('Trial count')
legend({'Presented','Engaged','nCorrect'},'location','northwest')
defaultAxesProperties(gca, false)
grid on

totalEngaged = sum(nEngaged(3:end))
totalCorrect = sum(nCorrect(3:end))
pCorrect = totalCorrect/totalEngaged

%% engagement for each speed combination

speedPairs = unique(combvec([ [allTrials.LeftVel]', [allTrials.RightVel]' ]),'rows');

% sort speed pairs
[d,idx]=unique(sort(speedPairs')','rows','stable');
us=speedPairs(idx,:);
idx=[];
for i=1:size(us,1)
    idx = [idx; find((all(ismember(speedPairs',us(i,:))',2)))];
end
speedPairs=speedPairs(idx,:);

for ipair = 1:size(speedPairs,1)
    tempTrials = allTrials([allTrials.LeftVel]==speedPairs(ipair,1) &...
        [allTrials.RightVel]==speedPairs(ipair,2) &...
        [allTrials.type]>=2); % active, engaged trials
    n_speedPair_all(ipair) = numel(tempTrials);
    nEng_speedPair(ipair) = sum([tempTrials.engaged]);
    pEng_speedPair(ipair) = nEng_speedPair(ipair)/n_speedPair_all(ipair);

end

subplot(312), hold on
b = bar(n_speedPair_all);
bar(nEng_speedPair)
ax=gca; ax.XTick=1:size(speedPairs,1);
for ipair = 1:size(speedPairs,1)
    ax.XTickLabel(ipair) = {[num2str(speedPairs(ipair,1)),'x',num2str(speedPairs(ipair,2))]};
    text(b.XData(ipair), b.YData(ipair)+5,num2str(pEng_speedPair(ipair),2),'HorizontalAlignment','center')
end
ylabel('Trial count')
xlabel('Left Vel x Right Vel')
legend({'presented', 'engaged'})
defaultAxesProperties(gca, false)
grid on

%% performance for each speed combination

speedPairs = unique(combvec([ [allTrials.LeftVel]', [allTrials.RightVel]' ]),'rows');

% sort speed pairs
[d,idx]=unique(sort(speedPairs')','rows','stable');
us=speedPairs(idx,:);
idx=[];
for i=1:size(us,1)
    idx = [idx; find((all(ismember(speedPairs',us(i,:))',2)))];
end
speedPairs=speedPairs(idx,:);

for ipair = 1:size(speedPairs,1)
    tempTrials = allTrials([allTrials.LeftVel]==speedPairs(ipair,1) &...
        [allTrials.RightVel]==speedPairs(ipair,2) &...
        [allTrials.type]>=2 & [allTrials.engaged]==1); % active, engaged trials
    n_speedPair(ipair) = numel(tempTrials);
    nCorr_speedPair(ipair) = sum([tempTrials.correct]);
    pCorr_speedPair(ipair) = nCorr_speedPair(ipair)/n_speedPair(ipair);

end

subplot(313), hold on
b = bar(n_speedPair);
bar(nCorr_speedPair)
ax=gca; ax.XTick=1:size(speedPairs,1);
for ipair = 1:size(speedPairs,1)
    ax.XTickLabel(ipair) = {[num2str(speedPairs(ipair,1)),'x',num2str(speedPairs(ipair,2))]};
    text(b.XData(ipair), b.YData(ipair)+5,num2str(pCorr_speedPair(ipair),2),'HorizontalAlignment','center')

end
ylabel('Trial count')
xlabel('Left Vel x Right Vel')
legend({'engaged, active trials', 'correct trials'})
defaultAxesProperties(gca, false)
grid on

%% imagesc plot of p(right)






