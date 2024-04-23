function session = importSDSessionFiles(folder)
% This function searches the input folder for .csv files produced by Bonsai
% and loads them as matlab tables within a session(nSession) struct

%% TO DO: 
% - check timestamps of matching files make sense! i.e. within x secs?
% - optionally emit 'video'? or give warnings? or just be verbose about
% everything?



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

if numel(unique([numEvents, numLicks, numTrialParams, numWheel, numVideoFiles])) ~= 1
    error('Unequal number of .csv files found in %s found, check directory', folder);
end

%% Match up files
% should match based on ordering of files
session = struct;

for isession = 1:numEvents
    session(isession).eventFile = eventFiles(isession).name;
    session(isession).lickFile = lickFiles(isession).name;
    session(isession).paramFile = paramFiles(isession).name;
    session(isession).wheelFile = wheelFiles(isession).name; 
    session(isession).videoFile = videoFiles(isession).name; 
end

%% loop through each 'session' and import csv files as tables

for isession = 1:numel(session)
    session(isession).events_tbl = readtable(fullfile(folder, session(isession).eventFile));
    session(isession).lick_tbl = readtable(fullfile(folder, session(isession).lickFile));
    session(isession).trialParams_tbl = readtable(fullfile(folder, session(isession).paramFile));
    session(isession).wheel_tbl = readtable(fullfile(folder, session(isession).wheelFile));
    session(isession).video_tbl = readtable(fullfile(folder, session(isession).videoFile));
end
