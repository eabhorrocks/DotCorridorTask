function scrollPlotHandle = plotSessionAsSeriesLABMEETING(events, params, trial, wheel, licks, saveflag)

% label trial type passive, active any....
% red is right, blue is left

% STIMULUS ON
% stim on is from stimON to stimOFF. need to find these intervals.
% find idx of stim on and stim off, find associated timestamps.
% for each interval, plot __|----|__
% load colormap
rbcmap = loadrbcolormap;
respOpenTimes = events.eTime(find(strcmp(events.tags, "respOPEN")));
respCloseTimes = events.eTime(find(strcmp(events.tags, "respCLOSED")));

figure, hold on
for itrial = 1:numel(events.trial.sontimes)
    
    % stim on
    fill([events.trial.sontimes(itrial), events.trial.sontimes(itrial), events.trial.sofftimes(itrial),...
        events.trial.sofftimes(itrial)], [9 10 10 9], 'k','LineStyle','none')
    
    % stim moving
    mTime = events.trial.movetimes(itrial); offTime = events.trial.sofftimes(itrial);
    Lmag = abs(trial(itrial).velXL); Rmag = abs(trial(itrial).velXR);
    speedDiff = Rmag - Lmag; 
    if speedDiff > 0
        idx = round(32+3*speedDiff);
        pCol = rbcmap(idx,:);
    elseif speedDiff < 0
        idx = round(32+3*speedDiff);
        pCol = rbcmap(idx,:);
    end
    fill([mTime, mTime, offTime, offTime], [9, 10, 10, 9], pCol)
%     fill([mTime, mTime, offTime,offTime], [9.5 9.5+Lscaled 9.5+Lscaled 9.5], 'c','LineStyle','none')
%     fill([mTime, mTime, offTime,offTime], [9 9+Rscaled 9+Rscaled 9], 'r','LineStyle','none')
    
    if itrial~=numel(events.trial.sontimes)
    plot([events.trial.sofftimes(itrial), events.trial.sontimes(itrial+1)], [9 9],'k-')
    end
    
    % plot resp window, 7.9-9
    plot([respOpenTimes(itrial), respOpenTimes(itrial)] , [8.2 10], 'k:', 'LineWidth', 1.5) 
    plot([respCloseTimes(itrial), respCloseTimes(itrial)] , [8.2 10], 'k:', 'LineWidth', 1.5)
    plot([respOpenTimes(itrial), respCloseTimes(itrial)], [8.2 8.2], 'k:','LineWidth', 1.5)
    plot([respOpenTimes(itrial), respCloseTimes(itrial)], [10 10], 'k:', 'LineWidth', 1.5)
    

end

plot([0, events.trial.sontimes(1)], [9 9],'k-')

plot(events.rewards.rrewardsTimes, 8.8*ones(size(events.rewards.rrewardsTimes)),  'ro', 'MarkerSize', 10);
plot(events.rewards.lrewardsTimes, 8.5*ones(size(events.rewards.lrewardsTimes)),  'bo', 'MarkerSize', 10);



for il = 1:numel(licks.lickTimeL)
    plot(licks.lickTimeL(il), 8.5, 'b.', 'MarkerSize', 12)
end
for ir = 1:numel(licks.lickTimeR)
    plot(licks.lickTimeR(ir), 8.8, 'r.', 'MarkerSize', 12)
end


plot(wheel.eTime, 6+(wheel.smthSpeed/max(wheel.smthSpeed))*2, 'Color', [0.2 0.2 0.2], 'LineWidth', 1.8)
plot([wheel.eTime(1), wheel.eTime(end)], [6 6], 'k-') 
plot([wheel.eTime(1), wheel.eTime(end)], [8 8], 'k-')


whlmaxstr = num2str(round(max(wheel.smthSpeed)))
whlmaxstr = [whlmaxstr, 'cm/s']
a = gca; 
a.YTick = [6, 7, 8, 8.65, 9.5]
a.YTickLabels = {'0 cm/s', 'Wheel Speed', whlmaxstr, 'Licks', 'Stimulus'}
xlabel('Session Time (s)', 'FontSize', 14)
dx=50;

% Set appropriate axis limits and settings
set(gcf,'doublebuffer','on');
%% This avoids flickering when updating the axis
set(a,'xlim',[0 dx]);
set(a,'ylim',[6 10.3]);
% Generate constants for use in uicontrol initialization
pos=get(a,'position');
Newpos=[pos(1) pos(2)-0.1 pos(3) 0.05];
%% This will create a slider which is just underneath the axis
%% but still leaves room for the axis labels above the slider
xmax=max(wheel.eTime);
S=['set(gca,''xlim'',get(gcbo,''value'')+[0 ' num2str(dx) '])'];
%% Setting up callback string to modify XLim of axis (gca)
%% based on the position of the slider (gcbo)
% Creating Uicontrol
scrollPlotHandle=uicontrol('style','slider',...
    'units','normalized','position',Newpos,...
    'callback',S,'min',0,'max',xmax-dx);

if saveflag == 1
    savefig(gcf, 'sessionAsSeries')
end