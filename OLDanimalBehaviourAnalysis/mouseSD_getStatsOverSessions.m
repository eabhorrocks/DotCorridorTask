%% Mouse Speed Discrimination analysis pipeline
%set(0,'DefaultFigureWindowStyle','docked');

mouseDir = 'X:\ibn-vision\DATA\SUBJECTS\M19145\SDTraining';
splitfold = split(mouseDir, '\');
subj = splitfold{5};

[trainingDays]  = GetSubDirsFirstLevelOnly(mouseDir);
nTrainingDays = numel(trainingDays);

day = struct;
tic

% 145 using 10:30 for full active, 26:30 (both), 
% 144 using 22nd nov (14th session) (26:29) for full, might be 24:27
for iDay = 26:nTrainingDays
    iDay
    
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


day(iDay).nActiveTrials = numel(activeTrials);
day(iDay).nEngagedTrials = numel(validTrials);
day(iDay).pEngaged = day(iDay).nEngagedTrials/day(iDay).nActiveTrials;
day(iDay).RTmean = nanmean([validTrials.RT]);
day(iDay).RTvar = nanvar([validTrials.RT]);



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
day(iDay).t70 = nanmean([speed.t70]);
day(iDay).bestt70 = min([speed.t70]);
day(iDay).bias = nanmean([speed.t50]);
day(iDay).speedt70both = [speed.t70];


%% metrics


% get diff trial types
correctTrials = validTrials(find([validTrials.result] ~= 0));
incorrectTrials = validTrials(find([validTrials.result] == 0));
runningTrials = validTrials(find([validTrials.runbool]==1));
mixedTrials = validTrials(find([validTrials.runbool]==-1));
statTrials = validTrials(find([validTrials.runbool]==0));

rSpeed = plotPsychSDRatio(runningTrials, options, options2);
day(iDay).run.t70 = nanmean([rSpeed.t70]);
day(iDay).run.bestt70 = min([rSpeed.t70]);
day(iDay).run.bias = nanmean([rSpeed.t50]);

try
sSpeed = plotPsychSDRatio(statTrials, options, options2);
catch
    warning('failed to get stat fit')
    day(iDay).stat.t70 = nan;
    day(iDay).stat.bestt70 = nan;
    day(iDay).stat.bias = nan;
end
day(iDay).stat.t70 = nanmean([sSpeed.t70]);
day(iDay).stat.bestt70 = min([sSpeed.t70]);
day(iDay).stat.bias = nanmean([sSpeed.t50]);

day(iDay).run.RT = nanmean([runningTrials.RT]);
day(iDay).stat.RT = nanmean([statTrials.RT]);



% running
nRunning = numel(find([validTrials.runbool]==1));
nStat = numel(find([validTrials.runbool]==0));
nMixed = numel(find([validTrials.runbool]==-1));


day(iDay).nRunning = nRunning;
day(iDay).nStat = nStat;
day(iDay).nMixed = nMixed;
day(iDay).pRunning = day(iDay).nRunning/day(iDay).nEngagedTrials;
day(iDay).pStat = day(iDay).nStat/day(iDay).nEngagedTrials;

day(iDay).speedT70Array = [[sSpeed.t70];[rSpeed.t70]];
day(iDay).trials = validTrials;




end
toc


save('M145_lastday_261121.mat', 'day')
%%
