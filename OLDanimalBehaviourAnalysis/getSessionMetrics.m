function [metrics, trial] = getSessionMetrics(trial, blockTags, plotflag, saveflag)


%% session metrics.
% lazy coding.
metrics = struct;

blockcat = [trial.type];

% number of trials for each block
for i = 1:numel(blockTags)
    metrics.blockidx.(blockTags{i}) = find(blockcat==blockTags{i});
    metrics.(blockTags{i}).nTrials = numel(metrics.blockidx.(blockTags{i}));
end

% number of engaged trials (a response, no manual reward) for each trial
% type
for ibtype = 1:numel(blockTags)
    idx = (metrics.blockidx.(blockTags{ibtype}));
    metrics.(blockTags{ibtype}).nEngaged = sum([trial(idx).engaged]);
    metrics.(blockTags{ibtype}).pEngaged =...
        metrics.(blockTags{ibtype}).nEngaged/metrics.(blockTags{ibtype}).nTrials;
    
    switch blockTags{ibtype}
        case 'passive'
            for itrial = 1:numel(idx)
                if trial(idx(itrial)).engaged == 1
                    validL = find(trial(idx(itrial)).licksL > trial(idx(itrial)).stimMoveTime...
                        & trial(idx(itrial)).licksL < trial(idx(itrial)).rewardtime);
                    validR = find(trial(idx(itrial)).licksR > trial(idx(itrial)).stimMoveTime...
                        & trial(idx(itrial)).licksR < trial(idx(itrial)).rewardtime);
                    
                    % left trials
                    if abs(trial(idx(itrial)).velXL) > abs(trial(idx(itrial)).velXR)
                        if isempty(validL)
                            trial(idx(itrial)).correct = 0;
                        elseif ~isempty(validL) && isempty(validR)
                            trial(idx(itrial)).correct = 1;
                        elseif min(validL) < min(validR)t
                            trial(idx(itrial)).correct = 1;
                        else
                            trial(idx(itrial)).correct = 0;
                        end
                        % right trials
                    elseif abs(trial(idx(itrial)).velXL) < abs(trial(idx(itrial)).velXR)
                        if isempty(validR)
                            trial(idx(itrial)).correct = 0;
                        elseif ~isempty(validR) && isempty(validL)
                            trial(idx(itrial)).correct = 1;
                        elseif min(validR) < min(validL)
                            trial(idx(itrial)).correct = 1;
                        else
                            trial(idx(itrial)).correct = 0;
                        end
                    end
                end
            end
            
        case 'activeany'
            for itrial = 1:numel(idx)
                if trial(idx(itrial)).engaged == 1
                    validL = find(trial(idx(itrial)).licksL > trial(idx(itrial)).respWinOpen...
                        & trial(idx(itrial)).licksL < trial(idx(itrial)).respWinClosed);
                    validR = find(trial(idx(itrial)).licksR > trial(idx(itrial)).respWinOpen...
                        & trial(idx(itrial)).licksR < trial(idx(itrial)).respWinClosed);
                    
                    % left trials
                    if abs(trial(idx(itrial)).velXL) > abs(trial(idx(itrial)).velXR)
                        if isempty(validL)
                            trial(idx(itrial)).correct = 0;
                        elseif ~isempty(validL) && isempty(validR)
                            trial(idx(itrial)).correct = 1;
                        elseif min(validL) < min(validR)
                            trial(idx(itrial)).correct = 1;
                        else
                            trial(idx(itrial)).correct = 0;
                        end
                        % right trials
                    elseif abs(trial(idx(itrial)).velXL) < abs(trial(idx(itrial)).velXR)
                        if isempty(validR)
                            trial(idx(itrial)).correct = 0;
                        elseif ~isempty(validR) && isempty(validL)
                            trial(idx(itrial)).correct = 1;
                        elseif min(validR) < min(validL)
                            trial(idx(itrial)).correct = 1;
                        else
                            trial(idx(itrial)).correct = 0;
                        end
                    end
                end
            end
            % licked on correct side first, otherwise engaged, otherwise not
        case 'activenoabort'
            for itrial = 1:numel(idx)
                if trial(idx(itrial)).engaged == 1
                    validL = find(trial(idx(itrial)).licksL > trial(idx(itrial)).respWinOpen...
                        & trial(idx(itrial)).licksL < trial(idx(itrial)).respWinClosed);
                    validR = find(trial(idx(itrial)).licksR > trial(idx(itrial)).respWinOpen...
                        & trial(idx(itrial)).licksR < trial(idx(itrial)).respWinClosed);
                    
                    % left trials
                    if abs(trial(idx(itrial)).velXL) > abs(trial(idx(itrial)).velXR)
                        if isempty(validL)
                            trial(idx(itrial)).correct = 0;
                        elseif ~isempty(validL) && isempty(validR)
                            trial(idx(itrial)).correct = 1;
                        elseif min(validL) < min(validR)
                            trial(idx(itrial)).correct = 1;
                        else
                            trial(idx(itrial)).correct = 0;
                        end
                        % right trials
                    elseif abs(trial(idx(itrial)).velXL) < abs(trial(idx(itrial)).velXR)
                        if isempty(validR)
                            trial(idx(itrial)).correct = 0;
                        elseif ~isempty(validR) && isempty(validL)
                            trial(idx(itrial)).correct = 1;
                        elseif min(validR) < min(validL)
                            trial(idx(itrial)).correct = 1;
                        else
                            trial(idx(itrial)).correct = 0;
                        end
                    end
                end
                
                if ((trial(idx(itrial)).response == 1 || trial(idx(itrial)).response == 2)...
                        && (trial(idx(itrial)).engaged == 1))
                    trial(idx(itrial)).correct2 = 1;
                else trial(idx(itrial)).correct2 = 0;
                end
            end
            
            % licked on correct side first, licked on correct side, licked only
            % incorrect, not engaged
        case 'active'
            for itrial = 1:numel(idx)
                if (trial(idx(itrial)).response == 1 || trial(idx(itrial)).response == 2)
                    trial(idx(itrial)).correct = 1;
                else trial(idx(itrial)).correct2 = 0;
                end
                if (trial(idx(itrial)).response == 0)
                    validL = find(trial(idx(itrial)).licksL > trial(idx(itrial)).respWinOpen...
                        & trial(idx(itrial)).licksL < trial(idx(itrial)).respWinClosed);
                    validR = find(trial(idx(itrial)).licksR > trial(idx(itrial)).respWinOpen...
                        & trial(idx(itrial)).licksR < trial(idx(itrial)).respWinClosed);
                    if (~isempty(validL) && ~isempty(validR))
                        trial(idx(itrial)).correct2 = 1;
                    else trial(idx(itrial)).correct2 = 0;
                    end
                end
                
                
                % correct or not. licked correct side after incorrect side.
            end
            
        case {'activevary', 'activevaryL','activehard'}
            for itrial = 1:numel(idx)
                if (trial(idx(itrial)).response == 1 || trial(idx(itrial)).response == 2)
                    trial(idx(itrial)).correct = 1;
                else trial(idx(itrial)).correct2 = 0;
                end
                if (trial(idx(itrial)).response == 0)
                    validL = find(trial(idx(itrial)).licksL > trial(idx(itrial)).respWinOpen...
                        & trial(idx(itrial)).licksL < trial(idx(itrial)).respWinClosed);
                    validR = find(trial(idx(itrial)).licksR > trial(idx(itrial)).respWinOpen...
                        & trial(idx(itrial)).licksR < trial(idx(itrial)).respWinClosed);
                    if (~isempty(validL) && ~isempty(validR))
                        trial(idx(itrial)).correct2 = 1;
                    else trial(idx(itrial)).correct2 = 0;
                    end
                end
                
                
                % correct or not. licked correct side after incorrect side.
            end
            
            
            % number of trials correct trials out of those engaged
            % for activeany, its if first lick was on right side
            % for activenoabort, first lick on right side OR 2ndry if response ~=3
            
    end
end



%% definitions
% engaged: licked during response window time, w/o manual reward
% correctness:
% passive: licked on right side once stim moved, before reward given
% activeany: licked right side first during response window
% activenoabort: licked on correct side first, correct2: licked on correct
% side after incorrect side.
% active: correct trial normal. correct2: licked the correct side 2nd.

for i = 1:numel(blockTags)
    metrics.(blockTags{i}).nCorrect = sum([trial(metrics.blockidx.(blockTags{i})).correct]);
    metrics.(blockTags{i}).nCorrect2 = sum([trial(metrics.blockidx.(blockTags{i})).correct2]);
    metrics.(blockTags{i}).pCorrect =...
        metrics.(blockTags{i}).nCorrect/metrics.(blockTags{i}).nEngaged;
    metrics.(blockTags{i}).pCorrect2 =...
        metrics.(blockTags{i}).nCorrect2/metrics.(blockTags{i}).nEngaged;
end




%% plots

if plotflag == 1

% nTrials bar chart
%blockTags = {'passive', 'activeany', 'activenoabort', 'active'};
labels = categorical(blockTags);
labels = reordercats(labels, blockTags);
nTrialVals = [];
pEngagedVals = [];
pCorrectVals = [];
pCorrect2Vals = [];
nEngagedVals = [];

for iblock = 1:numel(blockTags)
    nTrialVals = [nTrialVals, metrics.(blockTags{iblock}).nTrials];
    nEngagedVals = [nEngagedVals, metrics.(blockTags{iblock}).nEngaged];
    pEngagedVals = [pEngagedVals, metrics.(blockTags{iblock}).pEngaged];
    pCorrectVals = [pCorrectVals, metrics.(blockTags{iblock}).pCorrect];
    pCorrect2Vals = [pCorrect2Vals, metrics.(blockTags{iblock}).pCorrect2];
end

notEngagedVals = nTrialVals - nEngagedVals;
totalTrials = [nEngagedVals', notEngagedVals'];
figure
subplot(221)
bar(labels, totalTrials,'stacked')
ylabel('nTrials')
xlabel('block type')
title('nTrials')
legend({'engaged', 'not engaged'},'location','best')
box off


subplot(222)
bar(labels, pEngagedVals)
ylabel('proportion of trials')
xlabel('block type')
title('Proportion of Trials ''Engaged'' (Valid Trials)')
box off
ylim([0 1])


subplot(223)
yyaxis left
bar(labels, pCorrectVals)
ylabel('proportion of engaged trials')
xlabel('block type')
title('Full correct Trials (as proportion of engaged)')
box off
ylim([0 1])
yyaxis right
plot(labels, 0.5*ones(size(labels)), 'k--')
ylim([0 1])
yticks({})

subplot(224)
bar(labels, pCorrect2Vals)
ylabel('proportion of engaged trials')
xlabel('block type')
title('Correct2 Trials (diff under diff condns)')
box off
ylim([0 1])

if saveflag == 1
saveas(gcf, 'metrics.bmp')
end
end

