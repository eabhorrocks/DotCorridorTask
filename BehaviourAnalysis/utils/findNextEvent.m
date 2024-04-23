function [latency, index, absoluteTime, relativeTime] = findNextEvent(vectorOfTimes, eventTime)
temp = vectorOfTimes-eventTime;
temp(temp<0) = NaN;
[latency, index] = nanmin(abs(temp));
absoluteTime = vectorOfTimes(index);
relativeTime = absoluteTime-eventTime;
if isnan(latency)
    absoluteTime = NaN;
    relativeTime = NaN;
    latency = NaN;
    index = NaN;
end