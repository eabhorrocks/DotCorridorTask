function wheel = processWheel(wheel,smoothMethod,windowSize)

idx = find(isnan(wheel.eTime));

for i = 1:numel(idx) % interpolate any NaNs in elapsed time
    wheel.eTime(idx) = (wheel.eTime(idx-1) + wheel.eTime(idx+1) ) /2;
end

halfMax = max(wheel.pos)/2;
wheel.unwrapped = unwrap(wheel.pos, halfMax);
% not sure I have the right ticks per rev.
wheel.dist = wheel2unit(wheel.unwrapped, 1024, 17.78); % pos, ticks/rev, wheel diam

wheel.rawSpeed = diff(wheel.dist)./diff(wheel.eTime);
wheel.rawSpeed = movmean(wheel.rawSpeed, 2);
wheel.rawSpeed = [wheel.rawSpeed(1); wheel.rawSpeed];
wheel.smthSpeed = smoothdata(wheel.rawSpeed,smoothMethod,windowSize);

wheel.acc = diff(wheel.rawSpeed)./diff(wheel.eTime);
wheel.acc = movmean(wheel.acc,2);
wheel.acc = [wheel.acc(1); wheel.acc];
wheel.smthAcc = smoothdata(wheel.acc,smoothMethod,windowSize);

wheel.timeStat = numel(find(abs(wheel.rawSpeed)<1)) * median(diff(wheel.eTime));
wheel.timeMove = numel(find(abs(wheel.rawSpeed)>1)) * median(diff(wheel.eTime));

moveIdx = find(abs(wheel.rawSpeed)>1);
wheel.meanRunSpeed = mean(wheel.rawSpeed(moveIdx));
wheel.stdRunSpeed = std(wheel.rawSpeed(moveIdx));

