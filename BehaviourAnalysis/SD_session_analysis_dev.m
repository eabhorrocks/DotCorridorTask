%% Speed discrimination training session analysis (DEVELOPMENT)
clc, clear, close all % necessary for now

addpath(genpath('C:\Users\edward.horrocks\Documents\Code\GenericFunctions'));
addpath(genpath('C:\Users\edward.horrocks\Documents\Code\AnimalBehaviouralTasks\DotCorridorTask\BehaviourAnalysis'));


serverDir='Y:\ibn-vision\DATA\SUBJECTS\';
timeStamp2Use = 'ArduinoTime'; % 'ArduinoTime', 'BonsaiTime', [in any case should be ms] ?{or 'SyncPulse'}

%% Session details
Subject = 'M25123';
Session = '20260420';

sessionDir = fullfile(serverDir, Subject, 'training', Session);

%% import session files 

session = importSDSessionFiles(sessionDir);
nSessions = numel(session);

%% process wheel data to unwrap and get speed
wheelDiamater = 19; % clear wheel 
ticksPerRev = 4096;

for isession = 1:nSessions
    session(isession).wheel_tbl = processWheelTable_SD(session(isession).wheel_tbl, ...
        wheelDiamater, ticksPerRev, timeStamp2Use);
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
totalEngaged = sum(nEngaged(3:end));
totalCorrect = sum(nCorrect(3:end));
pCorrect = totalCorrect/totalEngaged;

%% Classify Stationary vs Running trials
% Movement Parameters
cfg.move.statMeanThresh = 3;  % Max mean speed for stationary
cfg.move.statPropThresh = 0.75; % Min proportion of time below window limit
cfg.move.statWinLimit   = 3.0;  % Speed limit for stationary window

cfg.move.runMeanThresh  = 3.0;  % Min mean speed for running
cfg.move.runPropThresh  = 0.75; % Min proportion of time above window limit
cfg.move.runWinLimit    = 0.5;  % Speed limit for running window

for itrial = 1:numel(allTrials)
    x = allTrials(itrial).runSpeedtoRT;
    if isempty(x)
        allTrials(itrial).isStat = false;
        allTrials(itrial).isRun = false;
        continue;
    end
    
    mSpeed = mean(x);
    propSlow = sum(x < cfg.move.statWinLimit) / numel(x);
    propFast = sum(x > cfg.move.runWinLimit)  / numel(x);
    
    allTrials(itrial).isStat = (propSlow >= cfg.move.statPropThresh) && (mSpeed < cfg.move.statMeanThresh);
    allTrials(itrial).isRun  = (propFast >= cfg.move.runPropThresh)  && (mSpeed > cfg.move.runMeanThresh);
end

fprintf('\nTrial classification by movement:\n');
fprintf('Stationary trials: %d\n', sum([allTrials.isStat]));
fprintf('Running trials:    %d\n', sum([allTrials.isRun]));
fprintf('Other/Ambiguous:   %d\n', sum(~[allTrials.isStat] & ~[allTrials.isRun]));

%% Prepare Data for Visualizations

% 1. Get unique speeds presented and calculate directional per-pair metrics
uL = unique([allTrials.LeftVel]);
uR = unique([allTrials.RightVel]);
[G1, G2] = ndgrid(uL, uR);
speedPairs = [G1(:), G2(:)];
actualPairs = unique([[allTrials.LeftVel]', [allTrials.RightVel]'], 'rows');
isPresented = ismember(speedPairs, actualPairs, 'rows');
speedPairs = speedPairs(isPresented, :);

% Sort speed pairs so that reciprocal pairs (e.g., 8x64 and 64x8) are adjacent
[~, idx] = unique(sort(speedPairs, 2), 'rows', 'stable');
us = sort(speedPairs(idx, :), 2);
sortedIdx = [];
for i = 1:size(us, 1)
    pairIdx = find(all(sort(speedPairs, 2) == us(i, :), 2));
    sortedIdx = [sortedIdx; pairIdx];
end
speedPairs = speedPairs(sortedIdx, :);

% Initialize metrics
n_speedPair_all = zeros(1, size(speedPairs, 1));
nEng_speedPair = zeros(1, size(speedPairs, 1));
pEng_speedPair = zeros(1, size(speedPairs, 1));
n_speedPair = zeros(1, size(speedPairs, 1));
nCorr_speedPair = zeros(1, size(speedPairs, 1));
pCorr_speedPair = zeros(1, size(speedPairs, 1));

for ipair = 1:size(speedPairs, 1)
    % All trials for this pair (active)
    idxAll = [allTrials.LeftVel]==speedPairs(ipair,1) & ...
             [allTrials.RightVel]==speedPairs(ipair,2) & ...
             [allTrials.type]>=2;
    n_speedPair_all(ipair) = sum(idxAll);
    
    if n_speedPair_all(ipair) > 0
        nEng_speedPair(ipair) = sum([allTrials(idxAll).engaged]);
        pEng_speedPair(ipair) = nEng_speedPair(ipair)/n_speedPair_all(ipair);
    end
    
    % Engaged trials for this pair (active)
    idxEng = idxAll & [allTrials.engaged]==1;
    n_speedPair(ipair) = sum(idxEng);
    
    if n_speedPair(ipair) > 0
        nCorr_speedPair(ipair) = sum([allTrials(idxEng).correct]);
        pCorr_speedPair(ipair) = nCorr_speedPair(ipair)/n_speedPair(ipair);
    end
end

% 2. Filter for active, engaged trials for aggregated psychometrics
isEngagedActive = [allTrials.type]>=2 & [allTrials.engaged]==1;
allEngagedActive = allTrials(isEngagedActive);

if ~isempty(allEngagedActive)
    % 1. Psychometric Curves Data
    signedLogRatio = log2([allEngagedActive.RightVel] ./ [allEngagedActive.LeftVel]);
    [uniqueSigned, ~, idxS] = unique(signedLogRatio);
    pRightAgg = zeros(size(uniqueSigned));
    nAggS = zeros(size(uniqueSigned));
    for i = 1:numel(uniqueSigned)
        trialIdx = (idxS == i);
        nAggS(i) = sum(trialIdx);
        pRightAgg(i) = sum([allEngagedActive(trialIdx).response] == 1) / nAggS(i);
    end
    
    absLogRatio = abs(signedLogRatio);
    [uniqueAbs, ~, idxA] = unique(absLogRatio);
    pCorrAgg = zeros(size(uniqueAbs));
    nAggA = zeros(size(uniqueAbs));
    for i = 1:numel(uniqueAbs)
        trialIdx = (idxA == i);
        nAggA(i) = sum(trialIdx);
        pCorrAgg(i) = sum([allEngagedActive(trialIdx).correct]) / nAggA(i);
    end

    % 2. Choice Preference Data (Agnostic to orientation)
    trialPairsAll = sort([[allEngagedActive.LeftVel]', [allEngagedActive.RightVel]'], 2);
    uniquePairIdentities = unique(trialPairsAll, 'rows');
    diffMask = uniquePairIdentities(:,1) ~= uniquePairIdentities(:,2);
    finalPairs = uniquePairIdentities(diffMask, :);
    ratios = max(finalPairs, [], 2) ./ min(finalPairs, [], 2);
    [~, sortIdx] = sort(ratios, 'descend');
    finalPairs = finalPairs(sortIdx, :);
end

%% Summary Visualizations
hFig = figure('Name', sprintf('Session Analysis: %s - %s', Subject, Session), ...
    'Color', 'w', 'Position', [50 50 1400 900]);

% --- Panel 1: Trial Counts Totals ---
subplot(2, 3, 1); hold on
bar(1:5, nTrials)
bar(1:5, nEngaged)
bar(1:5, nCorrect)
ax = gca; ax.XTick = 1:5; 
ax.XTickLabel = {'manual', 'passive','active-any','active-noabort','active'};
ylabel('Trial count')
legend({'Presented','Engaged','nCorrect'}, 'location', 'northwest', 'FontSize', 8)
title('Session Overview'); grid on;
defaultAxesProperties(gca, false)

% --- Panel 2: Accuracy by Speed Pair (Directional) ---
subplot(2, 3, 2); hold on
b = bar(n_speedPair);
bar(nCorr_speedPair)
ax = gca; ax.XTick = 1:size(speedPairs,1);
for ipair = 1:size(speedPairs,1)
    ax.XTickLabel{ipair} = [num2str(speedPairs(ipair,1)), 'x', num2str(speedPairs(ipair,2))];
    if n_speedPair(ipair) > 0
        text(b.XData(ipair), b.YData(ipair)+5, num2str(pCorr_speedPair(ipair), 2), 'HorizontalAlignment', 'center', 'FontSize', 8)
    end
end
ylabel('Trial count')
xlabel('Left Vel x Right Vel')
legend({'engaged trials', 'correct trials'}, 'location', 'northwest', 'FontSize', 8)
title('Accuracy by Speed pairs'); grid on;
defaultAxesProperties(gca, false)

% --- Panel 3: Heatmap: Left Speed vs Right Speed ---
subplot(2, 3, 3);
if ~isempty(allEngagedActive)
    uniqueSpeeds = unique([allEngagedActive.LeftVel, allEngagedActive.RightVel]);
    nSpeeds = numel(uniqueSpeeds);
    Data_Array = nan(nSpeeds);
    for r = 1:nSpeeds
        for c = 1:nSpeeds
            idx = [allEngagedActive.LeftVel] == uniqueSpeeds(r) & [allEngagedActive.RightVel] == uniqueSpeeds(c);
            if any(idx)
                Data_Array(r, c) = sum([allEngagedActive(idx).response] == 1) / sum(idx);
            end
        end
    end
    
    imAlpha = ones(size(Data_Array));
    imAlpha(isnan(Data_Array)) = 0;
    imagesc(Data_Array, 'AlphaData', imAlpha);
    
    
    axis xy; 
    cb = colorbar; cb.Label.String = 'p(Right)';
    colormap(gca, redblue);
    caxis([0 1]);
    xticks(1:nSpeeds); xticklabels(uniqueSpeeds);
    yticks(1:nSpeeds); yticklabels(uniqueSpeeds);
    xlabel('Right Speed'); ylabel('Left Speed');
    title('p(Right Response) Heatmap');
end
defaultAxesProperties(gca, false)
set(gca, 'color', 0*[1 1 1]);

% --- Panel 4: Choice Preference: Faster Left vs. Faster Right ---
subplot(2, 3, 4); hold on
groupSpacing = 1; withinGroupOffset = 0.2;
colors = lines(size(finalPairs, 1));
xTickPositions = []; xTickLabels = {};
for i = 1:size(finalPairs, 1)
    s1 = finalPairs(i, 1); s2 = finalPairs(i, 2);
    idxLF = [allEngagedActive.LeftVel] == s2 & [allEngagedActive.RightVel] == s1;
    pRight_LF = sum([allEngagedActive(idxLF).response] == 1) / sum(idxLF);
    idxRF = [allEngagedActive.LeftVel] == s1 & [allEngagedActive.RightVel] == s2;
    pRight_RF = sum([allEngagedActive(idxRF).response] == 1) / sum(idxRF);
    centerX = i * groupSpacing;
    x = [centerX - withinGroupOffset, centerX + withinGroupOffset];
    y = [pRight_LF, pRight_RF];
    plot(x, y, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2);
    scatter(x(1), y(1), sum(idxLF)*5+40, colors(i,:), 'filled', 'MarkerEdgeColor', 'k');
    scatter(x(2), y(2), sum(idxRF)*5+40, colors(i,:), 'filled', 'MarkerEdgeColor', 'k');
    xTickPositions(end+1) = centerX; xTickLabels{end+1} = sprintf('%d vs %d', s1, s2);
end
ylabel('p(Right Response)'); title('Choice Preference');
xticks(xTickPositions); xticklabels(xTickLabels);
yline(0.5, '--', 'Color', [0.4 0.4 0.4]);
ylim([0 1]); xlim([groupSpacing - 0.6, (size(finalPairs,1) * groupSpacing) + 0.6]);
grid on; defaultAxesProperties(gca, false);
if ~isempty(xTickPositions)
    text(xTickPositions(1)-withinGroupOffset, -0.05, '←L Fast', 'FontSize', 7, 'HorizontalAlignment', 'center');
    text(xTickPositions(1)+withinGroupOffset, -0.05, 'R Fast→', 'FontSize', 7, 'HorizontalAlignment', 'center');
end

% --- Panel 5: Psychometric Function (Signed) ---
subplot(2, 3, 5); hold on;
yline(0.5, '--', 'Color', [0.5 0.5 0.5]); xline(0, '--', 'Color', [0.5 0.5 0.5]);
plot(uniqueSigned, pRightAgg, 'k-', 'LineWidth', 1);
scatter(uniqueSigned, pRightAgg, nAggS*2 + 30, 'b', 'filled', 'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'k');
xlabel('log2(R / L)'); ylabel('p(Right)');
title('Sensitivity & Bias'); ylim([0 1]); grid on;
defaultAxesProperties(gca, false);

% --- Panel 6: Accuracy vs. Difficulty (Absolute) ---
subplot(2, 3, 6); hold on;
yline(0.5, '--', 'Color', [0.5 0.5 0.5]);
plot(uniqueAbs, pCorrAgg, 'k-', 'LineWidth', 1);
scatter(uniqueAbs, pCorrAgg, nAggA*2 + 30, 'r', 'filled', 'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'k');
xlabel('|log2(R / L)|'); ylabel('p(Correct)');
title('Accuracy vs. Difficulty'); ylim([0 1]); grid on;
defaultAxesProperties(gca, false);

%% Movement Performance Analysis
if ~isempty(allTrials)
    figure('Name', 'Trial Movement Analysis', 'Color', 'w', 'Position', [100 100 1200 600]);
    
    % Histogram of mean speeds
    subplot(2, 3, 1);
    allMeanSpeeds = [allTrials.meanRunSpeedtoRT];
    histogram(allMeanSpeeds, 20, 'FaceColor', [0.6 0.6 0.6]);
    xline(cfg.move.statMeanThresh, '--r', 'Stat Thresh', 'LabelHorizontalAlignment', 'center');
    xline(cfg.move.runMeanThresh, '--g', 'Run Thresh', 'LabelHorizontalAlignment', 'center');
    xlabel('Mean Trial Speed (cm/s)');
    ylabel('Number of Trials');
    title('Distribution of Trial Speeds');
    grid on; defaultAxesProperties(gca, false);
    
    % Breakdown of categories
    subplot(2, 3, 2);
    counts = [sum([allTrials.isStat]), sum([allTrials.isRun]), sum(~[allTrials.isStat] & ~[allTrials.isRun])];
    labels = {'Stat', 'Run', 'Amb'};
    b = bar(counts, 'FaceColor', 'flat');
    b.CData(1,:) = [0 0 0];    % Stat Black
    b.CData(2,:) = [1 0 0];    % Run Red
    b.CData(3,:) = [0.6 0.6 0.6]; % Amb Gray
    set(gca, 'XTickLabel', labels);
    ylabel('Trial Count');
    title('Trial Movement Breakdown');
    grid on; defaultAxesProperties(gca, false);
    
    % RT Distribution by Movement
    subplot(2, 3, 3); hold on;
    rtStat = [allTrials([allTrials.isStat]).RT];
    rtRun  = [allTrials([allTrials.isRun]).RT];
    histogram(rtStat, 'BinWidth', 100, 'FaceColor', 'k', 'FaceAlpha', 0.4, 'DisplayName', 'Stat');
    histogram(rtRun,  'BinWidth', 100, 'FaceColor', 'r', 'FaceAlpha', 0.4, 'DisplayName', 'Run');
    xlabel('RT (ms)'); ylabel('Trial Count');
    title('Reaction Time Distribution');
    legend('Location', 'northeast', 'FontSize', 8);
    grid on; defaultAxesProperties(gca, false);
    
    % Aligned Speed Traces
    timeGrid = -500:10:5000; % ms relative to stimulus onset
    classes = {'isStat', 'isRun', 'isAmb'};
    classNames = {'Stationary', 'Running', 'Ambiguous'};
    classColors = [0 0 0; 1 0 0; 0.6 0.6 0.6]; % Black, Red, Gray
    
    % Pre-calculate all traces to find shared max Y
    mTraces = cell(1,3); sTraces = cell(1,3); mMove = zeros(1,3); mOff = zeros(1,3);
    for c = 1:3
        if c == 1, idx = [allTrials.isStat];
        elseif c == 2, idx = [allTrials.isRun];
        else, idx = ~[allTrials.isStat] & ~[allTrials.isRun];
        end
        if any(idx)
            trialsC = allTrials(idx);
            speedsAgg = nan(numel(trialsC), numel(timeGrid));
            for it = 1:numel(trialsC)
                if ~isempty(trialsC(it).wheel)
                    speedsAgg(it, :) = interp1(trialsC(it).wheelTime, trialsC(it).wheel, timeGrid, 'linear', nan);
                end
            end
            mTraces{c} = nanmean(speedsAgg, 1);
            sTraces{c} = nanstd(speedsAgg, [], 1) ./ sqrt(sum(~isnan(speedsAgg), 1));
            mMove(c) = nanmean([trialsC.stimMoveTime]);
            mOff(c) = nanmean([trialsC.stimOffTime]);
        end
    end
    
    % Find shared maximum for the Y-axis
    sharedMax = 0;
    for c = 1:3
        if ~isempty(mTraces{c})
            sharedMax = max(sharedMax, max(mTraces{c} + sTraces{c}, [], 'omitnan'));
        end
    end
    if isempty(sharedMax) || sharedMax <= 0, sharedMax = 10; end % Fallback
    
    % Plotting loop with shared axis
    for c = 1:3
        subplot(2, 3, c+3); hold on;
        if ~isempty(mTraces{c})
            fill([timeGrid, fliplr(timeGrid)], [mTraces{c}-sTraces{c}, fliplr(mTraces{c}+sTraces{c})], ...
                 classColors(c,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            plot(timeGrid, mTraces{c}, 'Color', classColors(c,:), 'LineWidth', 1.5);
            xline(mMove(c), ':b', 'Dots Move', 'LabelVerticalAlignment', 'bottom', 'FontSize', 7);
            xline(mOff(c), ':r', 'Stim Off', 'LabelVerticalAlignment', 'bottom', 'FontSize', 7);
        end
        xlabel('Time from Stim Onset (ms)');
        ylabel('Speed (cm/s)');
        title(sprintf('Avg Trace: %s', classNames{c}));
        xline(0, '--k', 'Stim On', 'LabelVerticalAlignment', 'bottom', 'FontSize', 7);
        grid on; xlim([-500 5000]); ylim([0 sharedMax * 1.1]);
        defaultAxesProperties(gca, false);
    end
end
