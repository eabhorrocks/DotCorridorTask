%% set folder and tags of blocks
format compact
folder = 'X:\ibn-vision\DATA\SUBJECTS\M19145\SDTraining\191213'

saveflag = 0;
bonsai_with_responses = 1; % for new version which saves the response and outcome of the trial..
blockTags = {'activev2'};

%blockTags = {'passive', 'activeany', 'activenoabort', 'active', 'activevary','activevaryL','activehard'};

splitfold = split(folder, '\');
subj = splitfold{5};
seshDate = splitfold{7};
dirName = [subj '_' seshDate];
mkdir('C:\Users\edward.horrocks\Documents\GitHub\animalBehaviourAnalysis\FIGURES',...
    dirName)
newDir = ['C:\Users\edward.horrocks\Documents\GitHub\animalBehaviourAnalysis\FIGURES\',...
    dirName];
cd(newDir)
set(0,'DefaultFigureWindowStyle','docked')

%% import csv files

[events, params, wheel, licks] = importSessionFiles(folder, bonsai_with_responses);
% check for duplicate files, in which case create seperate folders?
% auto-catenate files would be nice.
%% get wheel speed
% wheel struct, smth window type, windowSize(bins)

wheel = processWheel(wheel, 'gaussian', 10);

%% Process events
[events, licks] = processEvents(events, licks, blockTags);

%% Generate trial struct
trial = genTrialStruct(events, params, wheel, licks);

%% session metrics
[metrics,trial] = getSessionMetrics(trial, blockTags, 1, saveflag); % plot flag, save flag

%% plot blocks trial-centric
for i = 1:numel(blockTags)
    plotTrials.(blockTags{i}) = trial(metrics.blockidx.(blockTags{i}));
    if ~isempty(plotTrials.(blockTags{i}))
        plotSDTrialBlock(plotTrials.(blockTags{i}), blockTags{i}, saveflag); % saveflag
    end
end

%% plot all full-active trials together, with speed map colourcoded
plotSDActiveTrials(trial, [subj ' ' seshDate], saveflag)

%% session as time series
scrollPlotHandle = plotSessionAsSeries(events, params, trial, wheel, licks, 1); % saveflag


%% GLM
% binofit to get CIs for simulated responses to stimuli.
[b, dev, stats, modelPerf, absSD, ten, ten2, resVec, yfit, yfit2] = SDGLM(trial);

%% plot psychometric curve
plotSDpsych(trial, metrics)


%% psytrack prep data
% bias
% stim left (array, [prev values as well)
% stim right
% speed difference
% average speed? (on last trial?)  prior stim history...
% previous correct answer
% previous choice

% get rid of invalid trials!
% 
% [y, s1, s2, prevAns, prevChoice, correctVec, answerVec] = makePsytrackInputs(trial);
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

%% dev catenate
% 
% for i= 1:6
%     
% pt3(i).sd = pt(i).sd;
% pt3(i).nTrials = pt(i).nTrials+pt2(i).nTrials;
% pt3(i).nR = pt(i).nR + pt2(i).nR;
% pt3(i).propR = pt(i).nR/pt(i).nTrials;
% 
% end
% 
% propR = [pt3.propR];
% 
% figure, hold on
% for i = 1:numel(speedDiffs)
% plot(speedDiffs(i), propR(i), 'bo', 'MarkerSize', pt(i).nR, 'MarkerFacecolor', 'b')
% end

% %% When are mice licking?
% % need to define time periods of different epochs.
% respWindowLength = 4;
% 
% epochs.stimOnNotMoving = [];
% epochs.stimOnMoving = [];
% epochs.respWindow = [];
% epochs.ISI = [];
% 
% for itrial = 1:numel(events.sontimes)-1
%     epochs.stimOnNotMoving = [epochs.stimOnNotMoving; trial(itrial).onTime, events.movetimes(itrial)];
%     epochs.stimOnMoving = [epochs.stimOnMoving; events.movetimes(itrial), events.sofftimes(itrial)];
%     epochs.respWindow = [epochs.respWindow; events.sofftimes(itrial), events.sofftimes(itrial)+respWindowLength]; % not meaningful for passive?
%     epochs.ISI = [epochs.ISI; events.sofftimes(itrial)+2, trial(itrial+1).onTime];
% end
% 
% % number of licks in:
% % stim on not moving
% 
% licks = struct;
% B1 = epochs.stimOnNotMoving;
% B2 = epochs.stimOnMoving;
% B3 = epochs.respWindow;
% B4 = epochs.ISI;
% 
% % left licks
% idx1 = false(size(events.lickTimeL));
% idx2 = false(size(events.lickTimeL));
% idx3 = false(size(events.lickTimeL));
% idx4 = false(size(events.lickTimeL));
% 
% for ii = 1:length(events.lickTimeL)
%     idx1(ii) = any((events.lickTimeL(ii)>B1(:,1))&(events.lickTimeL(ii)<B1(:,2)));
%     idx2(ii) = any((events.lickTimeL(ii)>B2(:,1))&(events.lickTimeL(ii)<B2(:,2)));
%     idx3(ii) = any((events.lickTimeL(ii)>B3(:,1))&(events.lickTimeL(ii)<B3(:,2)));
%     idx4(ii) = any((events.lickTimeL(ii)>B4(:,1))&(events.lickTimeL(ii)<B4(:,2)));
% end
% 
% licks.totals.stimOnNotMoving(1) = sum(idx1);
% licks.totals.stimOnMoving(1) = sum(idx2);
% licks.totals.respWindow(1) = sum(idx3);
% licks.totals.ISI(1) = sum(idx4);
% 
% clear idx1 idx2 idx3 idx4
% 
% % right licks
% 
% % left licks
% idx1 = false(size(events.lickTimeR));
% idx2 = false(size(events.lickTimeR));
% idx3 = false(size(events.lickTimeR));
% idx4 = false(size(events.lickTimeR));
% 
% for ii = 1:length(events.lickTimeR)
%     idx1(ii) = any((events.lickTimeR(ii)>B1(:,1))&(events.lickTimeR(ii)<B1(:,2)));
%     idx2(ii) = any((events.lickTimeR(ii)>B2(:,1))&(events.lickTimeR(ii)<B2(:,2)));
%     idx3(ii) = any((events.lickTimeR(ii)>B3(:,1))&(events.lickTimeR(ii)<B3(:,2)));
%     idx4(ii) = any((events.lickTimeR(ii)>B4(:,1))&(events.lickTimeR(ii)<B4(:,2)));
% end
% 
% licks.totals.stimOnNotMoving(2) = sum(idx1);
% licks.totals.stimOnMoving(2) = sum(idx2);
% licks.totals.respWindow(2) = sum(idx3);
% licks.totals.ISI(2) = sum(idx4);
% 
% clear idx1 idx2 idx3 idx4
% 
% % lick frequency (#licks/time in epoch)
% 
% licks.freqs.stimOnNotMoving = sum(licks.totals.stimOnNotMoving)/sum(B1(:,2)-B1(:,1));
% licks.freqs.stimOnMoving = sum(licks.totals.stimOnMoving)/sum(B2(:,2)-B2(:,1));
% licks.freqs.respWindow = sum(licks.totals.respWindow)/sum(B3(:,2)-B3(:,1));
% licks.freqs.ISI = sum(licks.totals.ISI)/sum(B4(:,2)-B4(:,1));
% 
% figure
% hb = bar([licks.freqs.stimOnNotMoving, licks.freqs.stimOnMoving, licks.freqs.respWindow, licks.freqs.ISI], 'FaceColor','flat')
% ylabel('mean lick frequency (Hz)')
% a = gca
% a.XTickLabel = [{'stat stim'}, {'moving stim'}, {'resp window'}, {'ISI'}];
% hb.CData = [.8 .8 .8; .6 .6 .6; .4 .4 .4; .2 .2 .2]
% box off
% %a.XTickLabelRotation = 45
% % want to check -> pre-emptive licks correct or not?
% 
