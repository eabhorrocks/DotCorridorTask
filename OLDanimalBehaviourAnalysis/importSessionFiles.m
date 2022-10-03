function [events, params, wheel, licks] = importSessionFiles(folder, bonsai_with_responses)

%% Events
filePattern = fullfile(folder, 'Events*.*');
fileList = dir(filePattern);
if numel(fileList)>1, error('multiple event files detected'), end
eventsFileName = [fileList.folder, '\' fileList.name]
[events.tags,events.ts] = importEventsFile(eventsFileName);

%% Trial Params
filePattern = fullfile(folder, 'TrialParams*.*');
fileList = dir(filePattern);
if numel(fileList)>1, error('multiple trial param files detected'), end
paramsFileName = [fileList.folder, '\' fileList.name]

% if bonsai_with_responses == 1
%     [params.trialID,params.trialDuration,params.dotSize,params.dotCol1,...
%         params.dotCol2,params.numDots1,params.numDots2,params.dotLifeBool,...
%         params.dotLifetime,params.contrast,params.velXLeft,params.velYLeft,...
%         params.cohLeft,params.velXRight,params.velYRight,params.cohRight,...
%         params.response, params.whichlick, params.ts] = importParamsFile2(paramsFileName, 2, inf);
% elseif bonsai_with_responses == 0
%     [params.trialID,params.trialDuration,params.dotSize,params.dotCol1,...
%         params.dotCol2,params.numDots1,params.numDots2,params.dotLifeBool,...
%         params.dotLifetime,params.contrast,params.velXLeft,params.velYLeft,...
%         params.cohLeft,params.velXRight,params.velYRight,params.cohRight,...
%         params.response, params.ts] = importParamsFile(paramsFileName, 2, inf);
% end

[params.TrialType,params.Response,params.Result,params.Contrast,...
    params.VelXLeft,params.VelXRight,params.CohLeft,params.CohRight,...
    params.ts] = SD_importTrialParamsFile(paramsFileName, 2, inf);


%% Wheel
filePattern = fullfile(folder, 'Wheel*.*');
fileList = dir(filePattern);
if numel(fileList)>1, error('multiple wheel files detected'), end
wheelFileName = [fileList.folder, '\' fileList.name]

[wheel.pos,wheel.ts] = importWheelFile(wheelFileName);

% below needs fixing: use elapsed time, and convert to cm
wheel.pos(1) = wheel.pos(2);

%% Licks
filePattern = fullfile(folder, 'Lick*.*');
fileList = dir(filePattern);
if numel(fileList)>1, error('multiple lick files detected'), end
licksFileName = [fileList.folder, '\' fileList.name]

[licks.leftLicks,licks.rightLicks,licks.ts] = importLicksFile(licksFileName, 2, inf);


%% convert datetimes to datenum and elapsed time
events.eTime = datenum(events.ts)*86400;
params.eTime = datenum(params.ts)*86400;
wheel.eTime = datenum(wheel.ts)*86400;
licks.eTime = datenum(licks.ts)*86400;

referenceTime = wheel.eTime(1);

events.eTime = events.eTime - referenceTime;
params.eTime = params.eTime - referenceTime;
wheel.eTime = wheel.eTime - referenceTime;
licks.eTime = licks.eTime - referenceTime;
end