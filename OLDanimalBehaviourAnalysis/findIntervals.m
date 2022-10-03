function [intervalArray, intervalTags, startIdxStruct] = findIntervals(inputVector, cellArrayOfTags, matchType)

%inputVector = events.tags; % vector of strings we are generating intervals
%from
%cellArrayOfTags = {'passive', 'activeany', 'activenoabort', 'active'};
intervalStartIdxs = [];

switch matchType
    case 'matches' % complete match of the string
        for i = 1:numel(cellArrayOfTags)
            fieldName = [cellArrayOfTags{i}, 'Starts'];
            temp.(fieldName) = find(inputVector==cellArrayOfTags{i});
            intervalStartIdxs = [intervalStartIdxs; temp.(fieldName)];
        end
        
    case 'contains' % contains the string
        for i = 1:numel(cellArrayOfTags)
            fieldName = [cellArrayOfTags{i}, 'Starts'];
            temp.(fieldName) = find(contains(inputVector,cellArrayOfTags{i}));
            intervalStartIdxs = [intervalStartIdxs; temp.(fieldName)];
        end        
end

startIdxStruct = temp;
intervalStartIdxs = sort(intervalStartIdxs);

if isempty(intervalStartIdxs)
    error('no intervals found, check cellArrayOfTags input arg')
end

if numel(intervalStartIdxs) > 1 % if there are multiple intervals
    
for i = 1:numel(intervalStartIdxs)-1
    temp_intervals(i,:) = [intervalStartIdxs(i), intervalStartIdxs(i+1)-1];
    temp_tags(i,:) = inputVector(intervalStartIdxs(i));
end

temp_intervals(end+1,:) = [intervalStartIdxs(end), inf];
temp_tags(end+1,:) = inputVector(intervalStartIdxs(end));

else % if there is only 1 intervals
    temp_intervals = [intervalStartIdxs(1), inf];
    temp_tags = inputVector(intervalStartIdxs(1));
end
intervalArray = temp_intervals;
intervalTags = temp_tags;
