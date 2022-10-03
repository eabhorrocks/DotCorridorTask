function [events, params, wheel, licks, nSessions] = importSessionFilesConcat(folder)

%% get session files
eventFiles = dir(fullfile(folder, 'Events*.*'));
lickFiles = dir(fullfile(folder, 'Licks*.*'));
paramFiles = dir(fullfile(folder, 'TrialParams*.*'));
wheelFiles = dir(fullfile(folder, 'Wheel*.*'));

% check equal number of files
numEvents = numel(eventFiles);
numLicks = numel(lickFiles);
numTrialParams = numel(paramFiles);
numWheel = numel(wheelFiles);

if numel(unique([numEvents, numLicks, numTrialParams, numWheel])) ~= 1
    error('Unequal number of session files, check directory')
end

% Match up files
session = struct;

for iSession = 1:numEvents
    session(iSession).eventFile = eventFiles(iSession).name;
    session(iSession).lickFile = lickFiles(iSession).name;
    session(iSession).paramFile = paramFiles(iSession).name;
    session(iSession).wheelFile = wheelFiles(iSession).name; 
end

% double check same dates - this breaks things if modified csv
% for iSession = 1:numel(session)
%     eventDate = eventFiles(iSession).date;
%     otherDates = {lickFiles(iSession).date, paramFiles(iSession).date, wheelFiles(iSession).date};
%     if ~all(vertcat(cellfun(@(c)strcmp(c,eventDate),otherDates,'UniformOutput',true)))
%         error(['dates of session files don''t line up for eventDate: ' eventDate]);
%     end
% end

%% loop through sessions loading event files

for iSession = 1:numel(session)
    [events(iSession).tags, events(iSession).ts] = ... 
        importEventsFile([folder '\' session(iSession).eventFile]);
    
    [params(iSession).TrialType,params(iSession).Response,params(iSession).Result,...
        params(iSession).Contrast,params(iSession).VelXLeft,params(iSession).VelXRight,...
        params(iSession).CohLeft,params(iSession).CohRight,params(iSession).ts] = ...
        SD_importTrialParamsFile([folder '\' session(iSession).paramFile],2,inf);
    
    [wheel(iSession).pos,wheel(iSession).ts] = ...
        importWheelFile([folder '\' session(iSession).wheelFile]);
    
    
    [licks(iSession).leftLicks,licks(iSession).rightLicks,licks(iSession).ts] = ...
        importLicksFile([folder '\' session(iSession).lickFile], 2, inf);
end


%% get proper times
% for each session get elapsed time by taking a reference time (wheel.eTime)
% if gap between two sessions is really large, set it to an arbitrary
% value, e.g. 1000 s

for iSession = 1:numel(session)
    events(iSession).eTime = datenum(events(iSession).ts)*86400;
    params(iSession).eTime = datenum(params(iSession).ts)*86400;
    wheel(iSession).eTime = datenum(wheel(iSession).ts)*86400;
    licks(iSession).eTime = datenum(licks(iSession).ts)*86400;
    
    referenceTime(iSession) = wheel(iSession).eTime(1);
    
    events(iSession).eTime = events(iSession).eTime - referenceTime(iSession);
    params(iSession).eTime = params(iSession).eTime - referenceTime(iSession);
    wheel(iSession).eTime = wheel(iSession).eTime - referenceTime(iSession);
    licks(iSession).eTime = licks(iSession).eTime - referenceTime(iSession);
    
end

nSessions = numel(session);

end