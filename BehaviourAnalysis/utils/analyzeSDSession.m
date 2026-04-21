function [summary, allTrials] = analyzeSDSession(sessionDir, cfg)
% ANALYZESDSESSION Performs core analysis for a single DotCorridorTask session.
%
% [summary, allTrials] = analyzeSDSession(sessionDir, cfg)
%
% summary: Struct containing session-wide scalar metrics (accuracy, bias, etc.)
% allTrials: Full trial structure array for the session
warning('on','all'); warning('backtrace','on');

%% Parameters & Path Setup
if nargin < 2
    % Default movement parameters
    cfg.move.statMeanThresh = 0.5;
    cfg.move.statPropThresh = 0.75;
    cfg.move.statWinLimit   = 3.0;
    cfg.move.runMeanThresh  = 3.0;
    cfg.move.runPropThresh  = 0.75;
    cfg.move.runWinLimit    = 0.5;
end

% Standard Task Params
wheelDiameter = 19;
ticksPerRev = 4096;
timeStamp2Use = 'ArduinoTime';

% Add Psignifit to path (assumed to be in repo toolboxes folder)
currPath = fileparts(mfilename('fullpath'));
toolboxPath = fullfile(currPath, '..', 'toolboxes', 'psignifit');
if exist(toolboxPath, 'dir')
    addpath(genpath(toolboxPath));
end

%% 1. Import Data
session = importSDSessionFiles(sessionDir);


%% 2. Process Wheel & Trials
for isession = 1:numel(session)
    session(isession).wheel_tbl = processWheelTable_SD(session(isession).wheel_tbl, ...
        wheelDiameter, ticksPerRev, timeStamp2Use);
    
    [session(isession).trials] = genTrialStruct(session(isession).events_tbl, ...
        session(isession).lick_tbl, session(isession).trialParams_tbl, ...
        session(isession).wheel_tbl, timeStamp2Use);
end

allTrials = cat(2, session.trials);
if isempty(allTrials)
    summary = []; return;
end

%% 3. Classify Movement
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

%% 4. Calculate Basic Session Metrics
nPresented = numel(allTrials);
isEngaged = [allTrials.engaged] == 1;
nEngaged = sum(isEngaged);

% Active, Engaged trials for performance
isActiveEngaged = [allTrials.type] >= 2 & isEngaged;
allPerf = allTrials(isActiveEngaged);

nPerf = numel(allPerf);
nCorrect = sum([allPerf.correct]);

summary.nTrials = nPresented;
summary.pEngaged = nEngaged / nPresented;
summary.pCorrect = nCorrect / nPerf;
summary.medianRT = median([allPerf.RT], 'omitnan');
summary.meanSpeed = mean([allTrials.meanRunSpeedtoRT], 'omitnan');
summary.percentRunning = sum([allTrials.isRun]) / nPresented;

%% 5. Formal Psychometric Fitting (Psignifit)
summary.bias = NaN;
summary.sensitivity = NaN;
summary.threshold70 = NaN;

if nPerf >= 20 % Minimum trials for a reasonable fit
    % Prepare data for psignifit: [stimulus_level, n_right, n_total]
    signedLogRatio = log2([allPerf.RightVel] ./ [allPerf.LeftVel]);
    [uniqueLevels, ~, idx] = unique(signedLogRatio);
    psigniData = zeros(numel(uniqueLevels), 3);
    for i = 1:numel(uniqueLevels)
        levelIdx = (idx == i);
        psigniData(i, 1) = uniqueLevels(i);               % Stimulus level
        psigniData(i, 2) = sum([allPerf(levelIdx).response] == 1); % nRight
        psigniData(i, 3) = sum(levelIdx);                  % nTotal
    end
    
    % Fit using Psignifit 4
    try
        options = struct;
        options.sigmoidName = 'norm'; % Gaussian cumulative
        options.expType = 'YesNo';    % Forced choice between two alternatives (L/R)
        
        result = psignifit(psigniData, options);
        
        % Bias (Threshold) is typically the PSE (where p(Right) = 0.5)
        summary.bias = getThreshold(result, 0.5);
        
        % Sensitivity is related to the Inverse of the Slope (Width in psignifit)
        summary.sensitivity = result.Fit(2); % Width parameter
        
        % --- Second fit for accuracy (Absolute Difficulty vs Correctness) ---
        absLogRatio = abs(signedLogRatio);
        [uLevelsAbs, ~, idxAbs] = unique(absLogRatio);
        psigniDataPerf = zeros(numel(uLevelsAbs), 3);
        for i = 1:numel(uLevelsAbs)
            lIdx = (idxAbs == i);
            psigniDataPerf(i, 1) = uLevelsAbs(i);
            psigniDataPerf(i, 2) = sum([allPerf(lIdx).correct]);
            psigniDataPerf(i, 3) = sum(lIdx);
        end
        
        optionsPerf = struct;
        optionsPerf.sigmoidName = 'norm';
        optionsPerf.expType = '2AFC'; % 0.5 to 1.0 accuracy
        resultPerf = psignifit(psigniDataPerf, optionsPerf);
        summary.threshold70 = getThreshold(resultPerf, 0.7);
        
    catch me
        warning('Psignifit failed for session: %s. Error: %s', sessionDir, me.message);
    end
end

end
