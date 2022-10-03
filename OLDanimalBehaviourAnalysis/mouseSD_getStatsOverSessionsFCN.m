function day = mouseSD_getStatsOverSessionsFCN(mouseDir, trainingDays, iDay)

    
% day = getStatsOverSessions(folder, trainingDays, iDay)

folder = [mouseDir '\' char(trainingDays(iDay))];
    
   
%% import csv files
[eventsRaw, paramsRaw, wheelRaw, licksRaw, nSessions] = importSessionFilesConcat(folder);

%% loop through sessions, generate trial struct

for iSession = 1:nSessions
    
    % process wheel (wheel struct, smth window type, windowSize(bins))
    wheelProcessed = processWheel(wheelRaw(iSession), 'gaussian', 10);
    wheel(iSession) = wheelProcessed;
    clear wheelProcessed
    
    % Process events
    [eventsProcessed, licksProcessed] = processEvents(eventsRaw(iSession), licksRaw(iSession));
    events(iSession) = eventsProcessed; 
    licks(iSession) = licksProcessed;
    clear licksProcessed eventsProcessed
    
    % Generate trial struct
    % for multiple sessions, want to just catenate on the end
    if iSession ~=1
        trials_temp = genTrialStruct(events(iSession), paramsRaw(iSession), wheel(iSession), licks(iSession));
        trials = [trials, trials_temp];
    else
    trials = genTrialStruct(events(iSession), paramsRaw(iSession), wheel(iSession), licks(iSession));
    end
    
end

%% generate different categories of trial...
% engaged, stat/walk, diff speeds(?)

activeTrials = trials(find([trials.type]=='activev2'));
validTrials = activeTrials(find([activeTrials.engaged]==1));
meanSpeeds = unique([validTrials.geoMean]);

% for ispeed = 1:numel(meanSpeeds)
%     speed(ispeed).trials = validTrials(find([validTrials.geoMean]==meanSpeeds(ispeed)));
% end


day.nActiveTrials = numel(activeTrials);
day.nEngagedTrials = numel(validTrials);
day.pEngaged = day.nEngagedTrials/day.nActiveTrials;
day.RT = nanmean([validTrials.RT]);



%% plot psychometric curves for each speed

% options for signed psychometric curves
options             = struct;   % initialize as an empty struct
options.sigmoidName = 'gauss'; %'rgumbel'   % choose a cumulative Gaussian as the sigmoid
options.expType     = 'YesNo';

% options for absolute value psychometric curve
options             = struct;   % initialize as an empty struct
options2.sigmoidName = 'gauss'; %'rgumbel'   % choose a cumulative Gaussian as the sigmoid
options2.expType     = '2AFC';
options2.poolxTol = 0.1;
options2.poolMaxGap = inf;
options2.poolMaxLength = inf;
options2.nblocks = 1;

speed = plotPsychSDRatio(validTrials, options, options2);
day.t70 = nanmean([speed.t70]);
day.bestt70 = min([speed.t70]);
day.bias = nanmean([speed.t50]);


%% metrics


% get diff trial types
correctTrials = validTrials(find([validTrials.result] ~= 0));
incorrectTrials = validTrials(find([validTrials.result] == 0));
runningTrials = validTrials(find([validTrials.runbool]==1));
mixedTrials = validTrials(find([validTrials.runbool]==-1));
statTrials = validTrials(find([validTrials.runbool]==0));

rSpeed = plotPsychSDRatio(runningTrials, options, options2);
day.run.t70 = nanmean([rSpeed.t70]);
day.run.bestt70 = min([rSpeed.t70]);
day.run.bias = nanmean([rSpeed.t50]);

try
sSpeed = plotPsychSDRatio(statTrials, options, options2);
catch
    warning('failed to get stat fit')
    day.stat.t70 = nan;
    day.stat.bestt70 = nan;
    day.stat.bias = nan;
end
day.stat.t70 = nanmean([sSpeed.t70]);
day.stat.bestt70 = min([sSpeed.t70]);
day.stat.bias = nanmean([sSpeed.t50]);

day.run.RT = nanmean([runningTrials.RT]);
day.stat.RT = nanmean([statTrials.RT]);



% running
nRunning = numel(find([validTrials.runbool]==1));
nStat = numel(find([validTrials.runbool]==0));
nMixed = numel(find([validTrials.runbool]==-1));


day.nRunning = nRunning;
day.nStat = nStat;
day.nMixed = nMixed;
day.pRunning = day.nRunning/day.nEngagedTrials;
day.pStat = day.nStat/day.nEngagedTrials;

day.speedT70Array = [[sSpeed.t70];[rSpeed.t70]];
day.trials = validTrials;