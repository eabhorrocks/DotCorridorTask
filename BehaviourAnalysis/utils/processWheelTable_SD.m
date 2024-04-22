function wheel_tbl = processWheelTable_SD(wheel_tbl, wheelDiameter, timestamp2use)

% unwrap wheel and convert to cm
halfMax = max(wheel_tbl.Wheel)/2;
wheel_tbl.Wheel = unwrap(wheel_tbl.Wheel, halfMax);
wheel_tbl.Distance = wheel2unit(wheel_tbl.Wheel, 1024, wheelDiameter);%.*-1; % pos, ticks/rev, wheel diam

% get speed at each timepoint
temp_speed = diff(wheel_tbl.Distance)./diff(wheel_tbl.(timestamp2use));
temp_speed = movmean(temp_speed, 2);
temp_speed = [temp_speed(1); temp_speed];

wheel_tbl.Speed = temp_speed*1000; % timestmap should be in ms

end
