%% Multi-Session Performance Tracking: DotCorridorTask
% This script iterates through all training sessions for a subject,
% extracts summary performance metrics, and plots longitudinal trends.

clc, clear, close all;

%% 1. Config & Paths
Subject = 'M25123';
serverDir = 'Y:\ibn-vision\DATA\SUBJECTS\';
repoDir = fileparts(mfilename('fullpath'));
resultsDir = fullfile(repoDir, 'results');
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

% Parameters for classification (can be tuned here)
cfg.move.statMeanThresh = 3.0;  % Following user latest manual edit
cfg.move.statPropThresh = 0.75;
cfg.move.statWinLimit   = 3.0;
cfg.move.runMeanThresh  = 3.0;
cfg.move.runPropThresh  = 0.75;
cfg.move.runWinLimit    = 0.5;

% Debugging/Filter: Only process sessions within this date range [YYYYMMDD YYYYMMDD]
% Set to [] to process all available sessions
cfg.dateRange = [ ];
cfg.forceRerun = true; % Set to true to re-process all sessions regardless of existing results



summaryFilePath = fullfile(resultsDir, sprintf('%s_summary.mat', Subject));

%% 2. Session Discovery
subjectTrainingDir = fullfile(serverDir, Subject, 'training');
allFolders = dir(subjectTrainingDir);
isDir = [allFolders.isdir];
isDate = arrayfun(@(x) length(x.name)==8 && all(isstrprop(x.name,'digit')), allFolders);
isSessionDir = isDir(:) & isDate(:);
sessionFolders = allFolders(isSessionDir);

% Apply date range filter if specified
if ~isempty(cfg.dateRange)
    sNames = str2double({sessionFolders.name});
    inRange = sNames >= cfg.dateRange(1) & sNames <= cfg.dateRange(2);
    sessionFolders = sessionFolders(inRange);
end

[~, sortIdx] = sort({sessionFolders.name});
sessionFolders = sessionFolders(sortIdx);

fprintf('Found %d session directories for Subject %s\n', numel(sessionFolders), Subject);

%% 3. Load/Initialize Results
if exist(summaryFilePath, 'file') && ~cfg.forceRerun
    load(summaryFilePath, 'resultsTable');
    processedSessions = resultsTable.Session;
    fprintf('Loaded existing results for %d sessions.\n', numel(processedSessions));
else
    if cfg.forceRerun
        fprintf('Force re-run enabled. Re-processing all sessions...\n');
    end
    resultsTable = table();
    processedSessions = {};
end

%% 4. Batch Processing
newSessionsFound = false;
for i = 1:numel(sessionFolders)
    sName = sessionFolders(i).name;
    
    % Skip if already processed (unless force rerun is on)
    if ~cfg.forceRerun && ismember(sName, processedSessions)
        continue;
    end
    
    fprintf('Processing session %s...\n', sName);
    sDir = fullfile(subjectTrainingDir, sName);
    
    % Skip sessions marked as BAD by the user
    if exist(fullfile(sDir, 'bad.txt'), 'file') || exist(fullfile(sDir, 'bad'), 'file')
        fprintf('Skipping session marked as BAD: %s\n', sName);
        continue;
    end
    
    [summary, ~] = analyzeSDSession(sDir, cfg);
    
    if ~isempty(summary)
        % Convert struct to single-row table
        summary.Session = sName;
        summary.Date = datetime(sName, 'InputFormat', 'yyyyMMdd');
        newRow = struct2table(summary, 'AsArray', true);
        
        % Append to results table
        if isempty(resultsTable)
            resultsTable = newRow;
        else
            resultsTable = [resultsTable; newRow];
        end
        newSessionsFound = true;
        
        % Save progress immediately to prevent data loss on crash
        save(summaryFilePath, 'resultsTable');
        processedSessions{end+1} = sName;
    else
        fprintf('Skipping empty/invalid session: %s\n', sName);
    end
end

if newSessionsFound
    % Ensure table is sorted by date
    [~, sortIdx] = sort(resultsTable.Date);
    resultsTable = resultsTable(sortIdx, :);
    save(summaryFilePath, 'resultsTable');
    fprintf('Saved updated results table to %s\n', summaryFilePath);
else
    fprintf('No new sessions to process.\n');
end

%% 5. Visualization: Longitudinal Dashboard
if ~isempty(resultsTable)
    hFig = figure('Name', sprintf('Longitudinal Performance: %s', Subject), ...
        'Color', 'w', 'Position', [100 100 1200 800]);
    
    % Use dates by default, or session indices as fallback
    xData = resultsTable.Date;
    xLabelStr = 'Date';
    
    % Panel 1: Throughput & Engagement
    subplot(2, 3, 1); hold on;
    yyaxis left
    plot(xData, resultsTable.nTrials, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6);
    ylabel('Total Trials');
    yyaxis right
    plot(xData, resultsTable.pEngaged * 100, 's--', 'LineWidth', 1, 'MarkerSize', 6);
    ylabel('% Engaged');
    grid on; title('Throughput & Engagement');
    
    % Panel 2: Accuracy (pCorrect)
    subplot(2, 3, 2); hold on;
    plot(xData, resultsTable.pCorrect * 100, 'k.-', 'LineWidth', 1.5, 'MarkerSize', 12);
    yline(50, '--', 'Chance', 'Color', [0.5 0.5 0.5]);
    ylim([30 100]); ylabel('% Correct');
    grid on; title('Overall Accuracy');
    
    % Panel 3: Psychometric Bias (PSE)
    subplot(2, 3, 3); hold on;
    plot(xData, resultsTable.bias, 'mo-', 'LineWidth', 1.5, 'MarkerSize', 6);
    yline(0, '--', 'Neutral', 'Color', [0.5 0.5 0.5]);
    ylabel('Bias (log2 R/L)');
    grid on; title('Choice Bias (Psignifit PSE)');
    
    % Panel 4: Movement (Percent Galloping/Running)
    subplot(2, 3, 4); hold on;
    plot(xData, resultsTable.percentRunning * 100, 'ro-', 'LineWidth', 1.5, 'MarkerSize', 6);
    ylabel('% Trials Running');
    grid on; title('Movement State');
    
    % Panel 5: Average Speed
    subplot(2, 3, 5); hold on;
    plot(xData, resultsTable.meanSpeed, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 6);
    ylabel('Mean Speed (cm/s)');
    grid on; title('Running Intensity');
    
    % Panel 6: Sensitivity & Thresholds
    subplot(2, 3, 6); hold on;
    plot(xData, resultsTable.sensitivity, 'co-', 'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', 'Width');
    if ismember('threshold70', resultsTable.Properties.VariableNames)
        plot(xData, resultsTable.threshold70, 'go--', 'LineWidth', 1, 'MarkerSize', 4, 'DisplayName', '70% Correct');
    end
    ylabel('log2(R/L)');
    grid on; title('Sensitivity & Thresholds');
    legend('Location', 'best', 'FontSize', 7);
    
    % Cleanup all axes
    for i = 1:6
        subplot(2,3,i);
        xlabel(xLabelStr);
        if isa(xData, 'datetime')
            xtickformat('MM-dd');
            xtickangle(45);
        end
    end
end
