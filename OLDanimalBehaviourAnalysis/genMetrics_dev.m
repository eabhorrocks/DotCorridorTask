%% session metrics.

metrics = struct;
blockTags = {'passive', 'activeany', 'activenoabort', 'active'};

blockcat = [trial.block];

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
                
                if (trial(idx(itrial)).response == 1 || trial(idx(itrial)).response == 2)
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


