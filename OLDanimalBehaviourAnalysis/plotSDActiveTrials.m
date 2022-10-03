function plotHandle = plotSDActiveTrials(trial,titleString,saveflag)

%% plot all active trials from a session together
% all relevant blocks mark as 'active'
% for each speed diff, group all those trials together,
% plot those trials, with the speed colour to the right
% load colormap
rbcmap = loadrbcolormap;
%plotTrials = trial(find([trial.block2]==1));
plotTrials = trial([trial.type]=='activev2');
uniqueSDs = unique([plotTrials.SD]);

sdtrial = struct();
for isd = 1:numel(uniqueSDs)
    sdtrial(isd).trials = plotTrials(find([plotTrials.SD]==uniqueSDs(isd)));
end
%%
trialCounter = 0;
yticks = trialCounter;
figure, hold on,
plot(-2:10, zeros(13,1), 'k--')
for isd = 1:numel(uniqueSDs)
    for itrial = 1:numel(sdtrial(isd).trials)
        trialCounter = trialCounter + 1;
        p = plot(sdtrial(isd).trials(itrial).licksL, repelem(trialCounter, 1, numel(sdtrial(isd).trials(itrial).licksL)), 'b.');
        p2= plot(sdtrial(isd).trials(itrial).licksR, repelem(trialCounter, 1, numel(sdtrial(isd).trials(itrial).licksR)), 'r.');
        
        if uniqueSDs(isd) < 0
            if ~isempty(sdtrial(isd).trials(itrial).rewardtime)
                p3= plot(sdtrial(isd).trials(itrial).rewardtime, trialCounter, 'bo');
            end
            if ~isempty(sdtrial(isd).trials(itrial).manualRewardTime)
                p4 = plot(sdtrial(isd).trials(itrial).manualRewardTime, trialCounter, 'bs');
            end
        elseif uniqueSDs(isd) > 0
            if ~isempty(sdtrial(isd).trials(itrial).rewardtime)
                p3= plot(sdtrial(isd).trials(itrial).rewardtime, trialCounter, 'ro');
            end
            if ~isempty(sdtrial(isd).trials(itrial).manualRewardTime)
                p4 = plot(sdtrial(isd).trials(itrial).manualRewardTime, trialCounter, 'rs');
            end
        end
        
        
    end
    plot(-2:10, repelem(trialCounter + 0.5, 13, 1), 'k--', 'Color', 'k')
    speedDiff = uniqueSDs(isd);
    if speedDiff > 0
        idx = round(32+3*speedDiff);
        pCol = rbcmap(idx,:);
    elseif speedDiff < 0
        idx = round(32+3*speedDiff);
        pCol = rbcmap(idx,:);
    end
    patch([7 7 8 8], [trialCounter-numel(sdtrial(isd).trials), trialCounter,...
        trialCounter, trialCounter-numel(sdtrial(isd).trials)], pCol)
    yticks = [yticks, trialCounter];
    
end

xlim([-1 8])

%% trial schematic stuff
fill([-2 0 0 3.5 3.5 10],  [trialCounter+10 trialCounter+10 trialCounter+20 ...
    trialCounter+20 trialCounter+10 trialCounter+10], [0 0 0])
fill([-2 1 1 3.5 3.5 10], [trialCounter+10 trialCounter+10 trialCounter+20 ...
    trialCounter+20 trialCounter+10 trialCounter+10], [.5 .5 .5])

yticks = [yticks, trialCounter+15];

plot([0 0], [0 trialCounter+10], 'k-.')
plot([1 1], [0 trialCounter+10], 'k-.')
plot([3.5 3.5], [0 trialCounter+10], 'k-.')


%% binned lick freq
edges = [-1:0.5:15];
licksVector = zeros(1,numel(edges));
for itrial = 1:numel(plotTrials)
%     itrialitrial

    Llicksdisc = discretize(plotTrials(itrial).licksL, edges);
    Rlicksdisc = discretize(plotTrials(itrial).licksR, edges);
    if ~isempty(Llicksdisc)
    for i=1:numel(Llicksdisc)
        licksVector(Llicksdisc(i)) = licksVector(Llicksdisc(i))+1;
    end
    end
    if ~isempty(Rlicksdisc)
    for i=1:numel(Rlicksdisc)
        licksVector(Rlicksdisc(i)) = licksVector(Rlicksdisc(i))+1;
    end
    end
    
end
maxlickfreq = 2*(max(licksVector)./numel(plotTrials))
licksVector = (licksVector/max(licksVector))*50;
plot(-1:0.5:9, licksVector(1:numel(-1:0.5:9))-50, 'k-', 'LineWidth', 2)
yticks = [-25, -1, yticks];


%% legend and y axis
h = zeros(2, 1);
h(1) = plot(NaN,NaN,'or', 'MarkerFaceColor', 'r');
h(2) = plot(NaN,NaN,'ob', 'MarkerFaceColor', 'b');
lgnd = legend(h, 'right','left');
lgnd.FontSize = 14;

xlabel('Trial Time (s)', 'FontSize', 14);
ylabel('Trials', 'FontSize', 14)
a = gca;
a.YTick = yticks;
a.YTickLabels{end} = 'Stimulus';
a.YTickLabels{1} = 'Trial-mean licks (Hz)';
a.YTickLabels{2} = [num2str(maxlickfreq)];
a.YTickLabels{3} = ' ';
title(titleString)
%%
plotHandle = gcf;


if saveflag == 1
    tosaveName = [titleString, 'allAtiveTrials.bmp'];
    saveas(gcf, tosaveName)
end