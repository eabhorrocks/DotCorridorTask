function session = importSDSessionFiles(folder)
% This function searches the input folder for .csv files produced by Bonsai
% and loads them as matlab tables within a session(nSession) struct

if ~exist(folder, 'dir')
    error('Directory does not exist: %s', folder);
end

%% get filenames of csv files
eventFiles = dir(fullfile(folder, '*Events*.csv'));
lickFiles = dir(fullfile(folder, '*Licks*.csv'));
paramFiles = dir(fullfile(folder, '*TrialParams*.csv'));
wheelFiles = dir(fullfile(folder, '*Wheel*.csv'));
videoFiles = dir(fullfile(folder, '*Video*.csv')); % csv files, not avi files


%% check equal number of files
numEvents = numel(eventFiles);
numLicks = numel(lickFiles);
numTrialParams = numel(paramFiles);
numWheel = numel(wheelFiles);
numVideoFiles = numel(videoFiles);

if numel(unique([numEvents, numLicks, numTrialParams, numWheel])) ~= 1
    error('Unequal number of core .csv files found in %s, check directory', folder);
end

if numVideoFiles > 0 && numVideoFiles ~= numEvents
    warning('Number of video files (%d) does not match number of event files (%d)', numVideoFiles, numEvents);
end

%% Match up files
% should match based on ordering of files
session = struct;

for isession = 1:numEvents
    session(isession).eventFile = eventFiles(isession).name;
    session(isession).lickFile = lickFiles(isession).name;
    session(isession).paramFile = paramFiles(isession).name;
    session(isession).wheelFile = wheelFiles(isession).name;
    if numVideoFiles > 0
        session(isession).videoFile = videoFiles(isession).name;
    else
        session(isession).videoFile = '';
    end
end

%% loop through each 'session' and import csv files as tables

for isession = 1:numel(session)
    session(isession).events_tbl = readtable(fullfile(folder, session(isession).eventFile));
    session(isession).lick_tbl = readtable(fullfile(folder, session(isession).lickFile));
    session(isession).trialParams_tbl = readtable(fullfile(folder, session(isession).paramFile));
    session(isession).wheel_tbl = readtable(fullfile(folder, session(isession).wheelFile));
    if ~isempty(session(isession).videoFile)
        session(isession).video_tbl = readtable(fullfile(folder, session(isession).videoFile));
    else
        session(isession).video_tbl = table();
    end
end
