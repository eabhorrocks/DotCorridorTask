%% Mouse Speed Discrimination analysis pipeline
%set(0,'DefaultFigureWindowStyle','docked');


folder = 'X:\ibn-vision\DATA\SUBJECTS\M23002\SDTraining\230301'
%folder = 'X:\ibn-vision\DATA\SUBJECTS\M19145\SDTraining\191204'

splitfold = split(folder, '\');
%subj = splitfold{5};
%seshDate = splitfold{7};

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
meanSpeeds = unique([trials.geoMean]);
validTrials = activeTrials(find([activeTrials.engaged]==1));

for ispeed = 1:numel(meanSpeeds)
    speed(ispeed).trials = validTrials(find([validTrials.geoMean]==meanSpeeds(ispeed)));
end

%% session plot
for ispeed = 1:numel(meanSpeeds)
plotHandle = plotSDenbloc(speed(ispeed).trials,['speed: ' num2str(meanSpeeds(ispeed))],0);
end

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

%% metrics


% get diff trial types
correctTrials = validTrials(find([validTrials.result] ~= 0));
incorrectTrials = validTrials(find([validTrials.result] == 0));
runningTrials = validTrials(find([validTrials.runbool]==1));
mixedTrials = validTrials(find([validTrials.runbool]==-1));
statTrials = validTrials(find([validTrials.runbool]==0));

% running
nRunning = numel(find([validTrials.runbool]==1))
nStat = numel(find([validTrials.runbool]==0))
nMixed = numel(find([validTrials.runbool]==-1))

% 
figure
histogram([correctTrials.meanRunSpeed], 20, 'FaceAlpha', 0.5), hold on
histogram([incorrectTrials.meanRunSpeed], 20, 'FaceAlpha', 0.5)
title('mean run speed'), box off
hold off

figure
histogram([correctTrials.varRunSpeed], 20, 'FaceAlpha', 0.5), hold on
histogram([incorrectTrials.varRunSpeed], 20, 'FaceAlpha', 0.5)
title('var run speed'), box off
hold off

figure
histogram([correctTrials.RT], 20, 'FaceAlpha', 0.5), hold on
histogram([incorrectTrials.RT], 20, 'FaceAlpha', 0.5)
title('RTs'), box off
hold off

%% plot stat vs run performance
options             = struct;   % initialize as an empty struct
options.sigmoidName = 'gauss'; %'rgumbel'   % choose a cumulative Gaussian as the sigmoid
options.expType     = 'YesNo';

trials = d144trials(26).trials;

statTrials = trials([trials.meanRunSpeed]<=5);
runTrials = trials([trials.meanRunSpeed]>=5);

speed = plotPsychSDRatio_RunvsStat(statTrials, runTrials, options)

%% PSYTRACK

% [y, s1, s2, prevAns, prevChoice, correctVec, answerVec] = makePsytrackInputs(validTrials);
% 
% inputFile = [newDir, '\' dirName 'psyinputs.mat'];
% outputFile = [newDir, '\' dirName 'psyoutput.mat'];
% save(inputFile,...
%     'y', 's1', 's2', 'prevAns', 'prevChoice', 'answerVec', 'correctVec');
% 
% sysCommand = ['C:\Users\edward.horrocks\PycharmProjects\pTrackProject\venv\Scripts\python.exe C:\Users\edward.horrocks\PycharmProjects\pTrackProject\venv\runPsyTrackSingleSesh.py -i ',...
%    inputFile ' -o ' outputFile];
% 
% % sysCommand = ['C:\Users\edward.horrocks\PycharmProjects\pTrackProject\venv\Scripts\python.exe C:\Users\edward.horrocks\PycharmProjects\pTrackProject\venv\runPsyTrackSingleSeshSimple.py -i ',...
% %     inputFile ' -o ' outputFile];
% 
% system(sysCommand)
% 
% load(outputFile)
% hold off, figure, hold on
% shadedErrorBar(1:numel(biasw),biasw, biasint./2, 'lineProps', 'k')
% shadedErrorBar(1:numel(biasw),s1w, s1int./2, 'lineProps', 'b')
% shadedErrorBar(1:numel(biasw),s2w, s2int./2, 'lineProps', 'r')
% shadedErrorBar(1:numel(biasw),pansw, pansint./2, 'lineProps', 'm')
% shadedErrorBar(1:numel(biasw),pchoicew, pchoiceint./2, 'lineProps', 'c')
% 
% legend({'bias', 'left vel', 'right vel', 'prev ans', 'prev choice'})
% ylabel('Weights');
% xlabel('Trial number')



%% psytrack prep data
% average speed, leftVel, rightVel, speedDifference (ratio)
% prevAns, prev choice

% 
% 
% maxVel = 900;
% y = [validTrials.response];
% y(y==1)=2;
% y(y==-1)=1;
% lvel = abs([validTrials.velXL]);
% rvel = abs([validTrials.velXR]);
% s1 = lvel./maxVel;
% s2 = rvel./maxVel;
% answerVec = [validTrials.answerVec];
% 
% answerVec = [];
% answerVec(lvel>rvel)=-1;
% answerVec(rvel>lvel)=1;
% 
% prevAns = [NaN, answerVec];
% prevChoice = [NaN, choice];
% y = [y NaN];
% s1 = [s1 NaN];
% s2 = [s2 NaN];
% answerVec = [answerVec NaN];
% choice = [choice NaN];
% correctVec = [correctVec NaN];
% 
% y = y';
% s1 = s1';
% s2 = s2';
% prevAns = prevAns';
% prevChoice = prevChoice';
% correctVec = correctVec';
% 
% %avSpeed = [lvel+rvel] for now is constant
% 
% todel = find(y==0);
% todel = [1; todel; numel(y)];
% 
% y(todel) = [];
% s1(todel)=[];
% s2(todel)=[];
% prevAns(todel)=[];
% prevChoice(todel)=[];
% answerVec(todel)=[];
% choice(todel)=[];
% correctVec(todel)=[];
% 
% 
% [y, s1, s2, prevAns, prevChoice, correctVec, answerVec] = makePsytrackInputs(validTrials);
% 
% inputFile = [newDir, '\' dirName 'psyinputs.mat'];
% outputFile = [newDir, '\' dirName 'psyoutput.mat'];
% save(inputFile,...
%     'y', 's1', 's2', 'prevAns', 'prevChoice', 'answerVec', 'correctVec');
% 
% sysCommand = ['C:\Users\edward.horrocks\PycharmProjects\pTrackProject\venv\Scripts\python.exe C:\Users\edward.horrocks\PycharmProjects\pTrackProject\venv\runPsyTrackSingleSesh.py -i ',...
%    inputFile ' -o ' outputFile];
% 
% % sysCommand = ['C:\Users\edward.horrocks\PycharmProjects\pTrackProject\venv\Scripts\python.exe C:\Users\edward.horrocks\PycharmProjects\pTrackProject\venv\runPsyTrackSingleSeshSimple.py -i ',...
% %     inputFile ' -o ' outputFile];
% 
% system(sysCommand)
% 
% load(outputFile)
% hold off, figure, hold on
% shadedErrorBar(1:numel(biasw),biasw, biasint./2, 'lineProps', 'k')
% shadedErrorBar(1:numel(biasw),s1w, s1int./2, 'lineProps', 'b')
% shadedErrorBar(1:numel(biasw),s2w, s2int./2, 'lineProps', 'r')
% shadedErrorBar(1:numel(biasw),pansw, pansint./2, 'lineProps', 'm')
% shadedErrorBar(1:numel(biasw),pchoicew, pchoiceint./2, 'lineProps', 'c')
% 
% legend({'bias', 'left vel', 'right vel', 'prev ans', 'prev choice'})
% ylabel('Weights');
% xlabel('Trial number')

% speedrun = plotPsychSDRatio(runningTrials, options, options2);
% speedmixed = plotPsychSDRatio(statTrials, options, options2);





    
    
    
    %% plot all trials
% psigMatrixAll = [speed(1).psigMatrix; speed(2).psigMatrix]
% psigresultAll = psignifit(psigMatrixAll);
% figure
% plotPsych(psigresultAll)





    
    % session metrics
    %[metrics,trial] = getSessionMetrics(trial, blockTags, 1, saveflag); % plot flag, save flag
%     
%     % plot blocks trial-centric
%     for i = 1:numel(blockTags)
%         plotTrials.(blockTags{i}) = trial(metrics.blockidx.(blockTags{i}));
%         if ~isempty(plotTrials.(blockTags{i}))
%             plotSDTrialBlock(plotTrials.(blockTags{i}), blockTags{i}, saveflag); % saveflag
%         end
%     end
%     
% end