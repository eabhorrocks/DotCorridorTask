function plotHandle = plotSDTrialBlock(trials,titleString,saveflag)

leftTrials = trials(abs([trials.velXL]) > abs([trials.velXR]));
rightTrials = trials(abs([trials.velXL]) < abs([trials.velXR]));

trialCounter = 0;
figure, hold on,
for itrial = 1:numel(leftTrials)
    trialCounter = trialCounter + 1;
    p = plot(leftTrials(itrial).licksL, repelem(trialCounter, 1, numel(leftTrials(itrial).licksL)), 'b.');
    p2= plot(leftTrials(itrial).licksR, repelem(trialCounter, 1, numel(leftTrials(itrial).licksR)), 'r.');
    if ~isempty(leftTrials(itrial).rewardtime)
    p3= plot(leftTrials(itrial).rewardtime, trialCounter, 'bo');
    end
    if ~isempty(leftTrials(itrial).manualRewardTime)
    p4 = plot(leftTrials(itrial).manualRewardTime, trialCounter, 'bs');
    end
end

plot(-2:10, repelem(trialCounter + 0.5, 13, 1), 'k--')


for itrial = 1:numel(rightTrials)
    trialCounter = trialCounter + 1;
    pp = plot(rightTrials(itrial).licksL, repelem(trialCounter, 1, numel(rightTrials(itrial).licksL)), 'b.');
    pp2= plot(rightTrials(itrial).licksR, repelem(trialCounter, 1, numel(rightTrials(itrial).licksR)), 'r.');
    if ~isempty(rightTrials(itrial).rewardtime)
    pp3= plot(rightTrials(itrial).rewardtime, trialCounter, 'ro');
    end
    if ~isempty(rightTrials(itrial).manualRewardTime)
    p4 = plot(rightTrials(itrial).manualRewardTime, trialCounter, 'rs');
    end
end

xlim([-1 8])

fill([-2 0 0 3.5 3.5 10],  [trialCounter+13 trialCounter+13 trialCounter+23 trialCounter+23 trialCounter+13 trialCounter+13], 'k-', 'LineWidth', 3)
plot([-2 1 1 3.5 3.5 10], [trialCounter+1 trialCounter+1 trialCounter+11 trialCounter+11 trialCounter+1 trialCounter+1], 'k--', 'LineWidth', 3)
plot([0 0], [0 trialCounter+12], 'k-.')
plot([1 1], [0 trialCounter+12], 'k-.')
plot([3.5 3.5], [0 trialCounter+12], 'k-.')

plotHandle = gcf;
a = gca;
a.YTick = [numel(leftTrials)/2, numel(leftTrials)+numel(rightTrials)/2, trialCounter+1, trialCounter+11, trialCounter+23];
a.YTickLabels = {'Left Trials', 'Right Trials', 'Stim off', 'Stim On', 'Stim Moving'};
title(titleString);
xlabel('Time (s)')

if saveflag == 1
    tosaveName = [titleString, 'Trials.bmp'];
    saveas(gcf, tosaveName)
end