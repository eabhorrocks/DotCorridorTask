function ph = plotSDpsych(trial, metrics)
activeTrialIndexes = sort([metrics.blockidx.activevary, metrics.blockidx.active, metrics.blockidx.activevaryL, metrics.blockidx.activehard]);
allActiveTrials = trial(activeTrialIndexes);

validRes = [0 1 2];
idx = ismember([allActiveTrials.response], validRes);
validTrials = allActiveTrials(idx);

ptrials = struct();

for i = 1:numel(validTrials)
    ptrials(i).delv = abs(validTrials(i).velXR)-abs(validTrials(i).velXL);
    ptrials(i).response = validTrials(i).response;
    if (ptrials(i).response == 2) || (ptrials(i).delv < 0 && ptrials(i).response==0)
        ptrials(i).rresp = 1;
    else
        ptrials(i).rresp = 0;
    end
end

pt = struct();

speedDiffs = unique([ptrials.delv])
for i = 1:numel(speedDiffs)
    pt(i).sd = speedDiffs(i);
    pt(i).trials = ptrials([ptrials.delv]==speedDiffs(i));
    pt(i).nTrials = numel(pt(i).trials);
    pt(i).nR = sum([pt(i).trials.rresp]);
    pt(i).propR = pt(i).nR/pt(i).nTrials;
    if pt(i).sd < 0
        pt(i).nCorr = pt(i).nTrials - pt(i).nR;
    elseif pt(i).sd > 0
        pt(i).nCorr = pt(i).nR;
    end
end

% find control speeds and remove from pt
idx1 = find([pt.sd]==-5);
idx2 = find([pt.sd]==-4.5);
idx3 = find([pt.sd]==4.5);
idx4= find([pt.sd]==5);
idx = [idx1, idx2,idx3,idx4];
ptCon = pt(idx);
pt(idx) = [];

propR = [pt.propR];
propRCon = [ptCon.propR];
speedDiffs = unique([pt.sd]);
speedDiffsCon = unique([ptCon.sd]);
% for i = 1:numel(speedDiffs)
% plot(speedDiffs(i), propR(i), 'bo', 'MarkerSize', pt(i).nTrials, 'MarkerFacecolor', 'b')
% end

%First we need the data in the format (x | nCorrect | total)
pSMatrix = [speedDiffs', [pt.nR]', [pt.nTrials]'];
pSMatrixCon = [speedDiffsCon', [ptCon.nR]', [ptCon.nTrials]'];

options             = struct;   % initialize as an empty struct
options.sigmoidName = 'logistic'; %'rgumbel'   % choose a cumulative Gaussian as the sigmoid
options.expType     = 'YesNo';
psResult = psignifit(pSMatrix,options);
if ~isempty(pSMatrixCon)
psResultCon = psignifit(pSMatrixCon, options);
end

plotOptions.dataColor      = [0,105/255,170/255];  % color of the data
plotOptions.plotData       = 1;                    % plot the data?
plotOptions.lineColor      = [0,0,0];              % color of the PF
plotOptions.lineWidth      = 2;                    % lineWidth of the PF
plotOptions.xLabel         = 'Speed Difference of Right Dots vs Left Dots';     % xLabel
plotOptions.yLabel         = 'Proportion Right Response';    % yLabel
%plotOptions.labelSize      = 15;                   % font size labels
%plotOptions.fontSize       = 10;                   % font size numbers
%plotOptions.fontName       = 'Helvetica';          % font
%plotOptions.tufteAxis      = false;                % use special axis
%plotOptions.plotAsymptote  = true;                 % plot Asympotes
%plotOptions.plotThresh     = true;                 % plot Threshold Mark
%plotOptions.aspectRatio    = false;                % set aspect ratio
%plotOptions.extrapolLength = .2;                   % extrapolation percentage
%plotOptions.CIthresh       = false;                % draw CI on threhold
%plotOptions.dataSize       = 10000./sum(result.data(:,3)) % size of the data-dots
figure
plotPsych(psResult, plotOptions);
box off
grid on
hold on,

if ~isempty(pSMatrixCon)
% 'MarkerSize',sqrt(plotOptions.dataSize*result.data(i,3))
plot([ptCon(1).sd ptCon(end).sd], [ptCon(1).propR, ptCon(end).propR], 'r-o', 'MarkerFaceColor', 'r')
plot([ptCon(2).sd ptCon(3).sd], [ptCon(2).propR, ptCon(3).propR], 'g-o', 'MarkerFaceColor', 'g')
end


plotOptions.dataColor      = [1,0,0];  % color of the data
plotOptions.plotData       = 1;                    % plot the data?
plotOptions.lineColor      = [1,1,1];              % color of the PF
plotOptions.lineWidth      = 0.01;                    % lineWidth of the PF
%plotPsych(psResultCon, plotOptions)
box off
grid on

%% create negative and positive data separately

negTrialsIdx = find([pt.sd]<0);
posTrialsIdx = find([pt.sd]>0);

negData = [];
posData = [];

for itrial = 1:numel(negTrialsIdx)
    negData(itrial,1) = abs(pt(negTrialsIdx(itrial)).sd); % speed diff
    negData(itrial,2) = pt(negTrialsIdx(itrial)).nCorr; % n correct (nTrials - nRight) for now...
    negData(itrial,3) = pt(negTrialsIdx(itrial)).nTrials;
end


for itrial = 1:numel(posTrialsIdx)
    posData(itrial,1) = abs(pt(posTrialsIdx(itrial)).sd); % speed diff
    posData(itrial,2) = pt(posTrialsIdx(itrial)).nCorr; % n right...
    posData(itrial,3) = pt(posTrialsIdx(itrial)).nTrials;
end

%biasAna(negData,posData,options)

options.expType = '2AFC';
options.sigmoidName = 'weibull';

absSDs = unique(abs(speedDiffs));

allData = NaN*ones(numel(absSDs),3);
corrVec = [pt.nCorr];
nTrialsVec = [pt.nTrials];
for i = 1:numel(absSDs)
    idx = find(abs([pt.sd])==absSDs(i));
    allData(i,1) = absSDs(i); % x val
    allData(i,2) = sum(corrVec(idx)); % n correct
    allData(i,3) = sum(nTrialsVec(idx)); % n trials
end


figure
allResult = psignifit(allData,options);
plotPsych(allResult)
