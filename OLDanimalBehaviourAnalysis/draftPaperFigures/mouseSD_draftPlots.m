%% draft plots for behaviour paper
set(0,'DefaultFigureWindowStyle','docked')

%% plot of total trials

nTrialsAll = padcat([d144trials.nActiveTrials], [d145trials.nActiveTrials]);
nTrialsMean = nanmean(nTrialsAll);

figure
plot(nTrialsAll', 'Color', [.7 .7 .7]), hold on
plot(nTrialsMean, 'Color', 'k', 'LineWidth', 2)
xlabel('Session num'), ylabel('nTrials');

%% training details - nTrials

fieldNames = {'nEngagedTrials', 'pEngaged', 'pRunning', 'RT'} 

for i=1:numel(fieldNames)
    figure
    fieldName = fieldNames{i};

allSubVals = padcat([d144trials.(fieldName)], [d145trials.(fieldName)]);
meanVals = nanmean(allSubVals);
%subplot(3,1,i)
plot(allSubVals', 'Color', [.7 .7 .7]), hold on
plot(meanVals, 'Color', 'k', 'LineWidth', 2)
xlabel('Session num'), ylabel(fieldName);
title([fieldName ' over training'])
ax = gca; ax.XTick
defaultAxesProperties(gca, true)

end
%%
subplot(311)
a = gca;
a.XTick = [];
xlabel([]);
subplot(312)
a = gca;
a.XTick = [];
xlabel([]);
subplot(313)
ylim([0 1])


%% training details - performance
fieldNames = {'bias', 't70'} 
figure
for i=2%1:numel(fieldNames)
    
    fieldName = fieldNames{i};

allSubVals = padcat(abs([day144.(fieldName)]), abs([day145.(fieldName)]));
meanVals = nanmean(allSubVals);
%subplot(2,1,i)
plot(allSubVals', 'Color', [.7 .7 .7]), hold on
plot(meanVals, 'Color', 'k', 'LineWidth', 2)
xlabel('Session num'), ylabel(fieldName);
title([fieldName ' over training'])

end
%%
subplot(211)
a = gca;
xlabel([]);
a.XTick = [];



%% thresholds for speed and run/walk

m144_allcat = cat(3,[d144trials(end-3).speedT70Array],[d144trials(end-2).speedT70Array],...
    [d144trials(end-1).speedT70Array], [d144trials(end).speedT70Array]);

% m145_allcat = cat(3,[d145trials(end-4).speedT70Array],[d145trials(end-3).speedT70Array],...
%     [d145trials(end-2).speedT70Array],[d145trials(end-1).speedT70Array],...
%     [day145(end).speedT70Array]);

m145_allcat = cat(3,[d145trials(end-3).speedT70Array],...
    [d145trials(end-2).speedT70Array],[d145trials(end-1).speedT70Array],...
    [d145trials(end).speedT70Array]);


m144_means = nanmean(m144_allcat,3);
m145_means = nanmean(m145_allcat,3);

figure, hold on
for i = 1:4
    plot([i-0.2, i+0.2], [m145_means(1,i), m145_means(2,i)], '-', 'Color', [.7 .7 .7])
    plot([i-0.2], [m145_means(1,i)], 'ko', 'MarkerFaceColor', 'r')
    plot([i+0.2], [m145_means(2,i)], 'ko', 'MarkerFaceColor', 'g')
end

for i = 1:4
    plot([i-0.2, i+0.2], [m144_means(1,i), m144_means(2,i)], '-', 'Color', [.7 .7 .7])
    plot([i-0.2], [m144_means(1,i)], 'ks', 'MarkerFaceColor', 'r')
    plot([i+0.2], [m144_means(2,i)], 'ks', 'MarkerFaceColor', 'g')
end

ylabel('70% Threshold (log speed ratio)')
xlabel('Geometric Mean Speed')
title('Performance over speed and state')
a = gca;
a.XTick = [1,2,3,4];
a.XTickLabel = {'100', '200', '300', '400'}
ylim([0 2.2]);


%% plot left and right trials separately

leftTrials = validTrials(find([validTrials.geoRatio]<1));
rightTrials = validTrials(find([validTrials.geoRatio]>1));

leftHandle = plotSDenbloc(leftTrials,[],0);
xlim([-1 7])
ylabel([])
ylim([0 450])

rightHandle = plotSDenbloc(rightTrials,[],0);
xlim([-1 7])
ylabel([])
ylim([0 450])


allTrials = plotSDenbloc(validTrials,[],0);
xlim([-1 6.95])
ylabel([])
ylim([0 900])
set(gca, 'Ycolor', 'w')
set(gca, 'YTick', [])

%% plot all trials as psychometric curve
% options for signed psychometric curves
options             = struct;   % initialize as an empty struct
options.sigmoidName = 'gauss'; %'rgumbel'   % choose a cumulative Gaussian as the sigmoid
options.expType     = 'YesNo';
plotPsychSDRatioAllTrials(validTrials, options)





%% SPLIT BY SPEED AND STATE
% options for signed psychometric curves
options             = struct;   % initialize as an empty struct
options.sigmoidName = 'gauss'; %'rgumbel'   % choose a cumulative Gaussian as the sigmoid
options.expType     = 'YesNo';

% options for absolute value psychometric curve
options2             = struct;   % initialize as an empty struct
options2.sigmoidName = 'gauss'; %'rgumbel'   % choose a cumulative Gaussian as the sigmoid
options2.expType     = '2AFC';
options2.poolxTol = 0.1;
options2.poolMaxGap = inf;
options2.poolMaxLength = inf;
options2.nblocks = 1;

load('m145_4speeds.mat')
load('m144_4speeds.mat')

% combine trials across sessions and mice. Doesnt work well. not enough
% stat sampling.
allTrials = [day144_4speeds.trials, day145_4speeds.trials];
%RunTrials = allTrials(find([allTrials.runbool]==1));
%StatTrials = allTrials(find([allTrials.runbool]==0));
RunTrials = allTrials([allTrials.meanRunSpeed]>=5);
StatTrials = allTrials([allTrials.meanRunSpeed]<3);

% need to sort out the abs ratios

statSpeed = plotPsychSDRatio(StatTrials, options, options2);
runSpeed = plotPsychSDRatio(RunTrials, options, options2);





%% analyse performance w/ stats
load('m144_alltrials.mat')
load('m145_alltrials.mat')

all144 = [d144trials(end-3:end).trials];
all145 = [d145trials(end-3:end).trials];

for itrial = 1:numel(all144)
    if all144(itrial).absRatio<1
        temp = 1/all144(itrial).absRatio;
        if abs(temp-1.65)<0.1
            temp = 1.65;
        elseif abs(temp-3.5)<0.1
            temp = 3.5;
        elseif abs(temp-8)<0.4
            temp = 8;
        end
        all144(itrial).absRatio = temp;
    end
end

for itrial = 1:numel(all145)
    if all145(itrial).absRatio<1
        temp = 1/all145(itrial).absRatio;
        if abs(temp-1.65)<0.1
            temp = 1.65;
        elseif abs(temp-3.5)<0.1
            temp = 3.5;
        elseif abs(temp-8)<0.4
            temp = 8;
        end
        all145(itrial).absRatio = temp;
    end
end

%% fraction of easiest trials correct.

p8(1) = prop([all144([all144.absRatio]==8).result]);
p8(2) = prop([all145([all145.absRatio]==8).result]);
mean(p8), sem(p8,2)


%% get sig from chance over last 4 sessions
ratio = 1.65;
for isesh = 1:4
    t = d144trials((end-4)+isesh).trials;
    for itrial = 1:numel(t)
     if t(itrial).absRatio<1
        temp = 1/all145(itrial).absRatio;
        if abs(temp-1.65)<0.1
            temp = 1.65;
        elseif abs(temp-3.5)<0.1
            temp = 3.5;
        elseif abs(temp-8)<0.4
            temp = 8;
        end
        t(itrial).absRatio = temp;
     end
    end
    t = t([t.absRatio]==ratio);
    p144(isesh) = prop([t.result]);
    
    
    t = d145trials((end-4)+isesh).trials;
     for itrial = 1:numel(t)
     if t(itrial).absRatio<1
        temp = 1/all145(itrial).absRatio;
        if abs(temp-1.65)<0.1
            temp = 1.65;
        elseif abs(temp-3.5)<0.1
            temp = 3.5;
        elseif abs(temp-8)<0.4
            temp = 8;
        end
        t(itrial).absRatio = temp;
     end
     end
    t = t([t.absRatio]==ratio);
    p145(isesh) = prop([t.result]);
end
    

p144
p145


%% Plot behaviour (reaction times and run speed)
%all144 = [day144_4speeds.trials];
%all145 = [day145_4speeds.trials];

% convert ratios to > 1
for itrial = 1:numel(all144)
     if all144(itrial).absRatio<1
        temp = 1/all144(itrial).absRatio;
        if abs(temp-1.65)<0.1
            temp = 1.65;
        elseif abs(temp-3.5)<0.1
            temp = 3.5;
        elseif abs(temp-8)<0.4
            temp = 8;
        end
        all144(itrial).absRatio = temp;
     end
end

for itrial = 1:numel(all145)
     if all145(itrial).absRatio<1
        temp = 1/all145(itrial).absRatio;
        if abs(temp-1.65)<0.1
            temp = 1.65;
        elseif abs(temp-3.5)<0.1
            temp = 3.5;
        elseif abs(temp-8)<0.4
            temp = 8;
        end
        all145(itrial).absRatio = temp;
     end
end


%% plot mean run traces by speed

run144 = all144([all144.meanRunSpeed]>=5);
run145 = all145([all145.meanRunSpeed]>=5);


figure, hold on
cols = inferno(4);
for ispeed = 1:4
    temp144 = run144([run144.geoMean]==ispeed*100);
    runTrace144 = padcat(temp144.wheel)';
    shadedErrorBar(1:330, nanmean(runTrace144(:,1:330),1), nansem(runTrace144(:,1:330),1), 'lineProps', {'Color', cols(ispeed,:)})
end
plot([60 60], [0 25], 'k:')
plot([120 120], [0 25], 'k:')
plot([270 270], [0 25], 'k:')
ylim([0 25])
ax = gca; ax.XTick = [0 60 120 270 330];
title('144')
defaultAxesProperties(gca, true)

figure, hold on
cols = inferno(4);
for ispeed = 1:4
    temp145 = run145([run145.geoMean]==ispeed*100);
    runTrace145 = padcat(temp145.wheel)';
    shadedErrorBar(1:330, nanmean(runTrace145(:,1:330),1), nansem(runTrace145(:,1:330),1), 'lineProps', {'Color', cols(ispeed,:)})
end
plot([60 60], [0 25], 'k:')
plot([120 120], [0 25], 'k:')
plot([270 270], [0 25], 'k:')
ylim([0 22])
ax = gca; ax.XTick = [0 60 120 270 330];
title('145')
defaultAxesProperties(gca, true)

%% correct vs incorrect run traces
all144_corr = run144([run144.result]~=0); % running trials only
all144_incorr = run144([run144.result]==0);

figure
subplot(2,2,1), hold on
temp144 = all144_corr;
runTrace144 = padcat(temp144.wheel)';
shadedErrorBar(1:330, nanmean(runTrace144(:,1:330),1), nansem(runTrace144(:,1:330),1), 'lineProps', {'Color', 'r'})
temp144 = all144_incorr;
runTrace144 = padcat(temp144.wheel)';
shadedErrorBar(1:330, nanmean(runTrace144(:,1:330),1), nansem(runTrace144(:,1:330),1), 'lineProps', {'Color', 'k'})
plot([60 60], [0 35], 'k:')
plot([120 120], [0 35], 'k:')
plot([270 270], [0 35], 'k:')
ylim([0 35])
ax = gca; ax.XTick = [0 60 120 270 330];
title('144 correct vs incorrect')
defaultAxesProperties(gca, true)


all145_corr = run145([run145.result]~=0); % running trials only
all145_incorr = run145([run145.result]==0);
%figure, 
subplot(2,2,3), hold on
temp145 = all145_corr;
runTrace145 = padcat(temp145.wheel)';
shadedErrorBar(1:330, nanmean(runTrace145(:,1:330),1), nansem(runTrace145(:,1:330),1), 'lineProps', {'Color', 'r'})
temp145 = all145_incorr;
runTrace145 = padcat(temp145.wheel)';
shadedErrorBar(1:330, nanmean(runTrace145(:,1:330),1), nansem(runTrace145(:,1:330),1), 'lineProps', {'Color', 'k'})
plot([60 60], [0 25], 'k:')
plot([120 120], [0 25], 'k:')
plot([270 270], [0 25], 'k:')
ylim([0 25])
ax = gca; ax.XTick = [0 60 120 270 330];
title('145 correct vs incorrect')
defaultAxesProperties(gca, true)

%% Remove fast RTs correct vs incorrect run traces
RTthresh = 0.2;
all144_corr = run144([run144.result]~=0 & [run144.RT]<=RTthresh); % running trials only
all144_incorr = run144([run144.result]==0  & [run144.RT]<=RTthresh);


subplot(2,2,2), hold on
temp144 = all144_corr;
runTrace144 = padcat(temp144.wheel)';
shadedErrorBar(1:330, nanmean(runTrace144(:,1:330),1), nansem(runTrace144(:,1:330),1), 'lineProps', {'Color', 'r'})
temp144 = all144_incorr;
runTrace144 = padcat(temp144.wheel)';
shadedErrorBar(1:330, nanmean(runTrace144(:,1:330),1), nansem(runTrace144(:,1:330),1), 'lineProps', {'Color', 'k'})
plot([60 60], [0 35], 'k:')
plot([120 120], [0 35], 'k:')
plot([270 270], [0 35], 'k:')
ylim([0 35])
ax = gca; ax.XTick = [0 60 120 270 330];
title('144 correct vs incorrect (no fast)')
defaultAxesProperties(gca, true)


all145_corr = run145([run145.result]~=0  & [run145.RT]<=RTthresh); % running trials only
all145_incorr = run145([run145.result]==0  & [run145.RT]<=RTthresh);
subplot(2,2,4), hold on
temp145 = all145_corr;
runTrace145 = padcat(temp145.wheel)';
shadedErrorBar(1:330, nanmean(runTrace145(:,1:330),1), nansem(runTrace145(:,1:330),1), 'lineProps', {'Color', 'r'})
temp145 = all145_incorr;
runTrace145 = padcat(temp145.wheel)';
shadedErrorBar(1:330, nanmean(runTrace145(:,1:330),1), nansem(runTrace145(:,1:330),1), 'lineProps', {'Color', 'k'})
plot([60 60], [0 25], 'k:')
plot([120 120], [0 25], 'k:')
plot([270 270], [0 25], 'k:')
ylim([0 25])
ax = gca; ax.XTick = [0 60 120 270 330];
title('145 correct vs incorrect (no fast)')
defaultAxesProperties(gca, true)


%% plot mean run speed correct vs incorrect

% figure
% histogram([all144_corr.meanRunSpeed], 'normalization', 'probability','BinWidth',3), hold on
% histogram([all144_incorr.meanRunSpeed], 'normalization', 'probability','BinWidth',3)
% plot(mean([all144_corr.meanRunSpeed]), 0.25, 'v', 'MarkerFaceColor','b')
% plot(mean([all144_incorr.meanRunSpeed]), 0.25, 'v', 'MarkerFaceColor','r')
% ylabel('Probability')
% xlabel('Mean Running Speed')
% [h, p] = ttest2([all144_corr.meanRunSpeed],[all144_incorr.meanRunSpeed]);
% xlim([-10 50])
% title(['144, p=' num2str(p,3)])
% defaultAxesProperties(gca, false)
% 
% figure
% histogram([all145_corr.meanRunSpeed], 'normalization', 'probability','BinWidth',3), hold on
% histogram([all145_incorr.meanRunSpeed], 'normalization', 'probability','BinWidth',3)
% plot(mean([all145_corr.meanRunSpeed]), 0.25, 'v', 'MarkerFaceColor','b')
% plot(mean([all145_incorr.meanRunSpeed]), 0.25, 'v', 'MarkerFaceColor','r')
% ylabel('Probability')
% xlabel('Mean Running Speed')
% [h, p] = ttest2([all145_corr.meanRunSpeed],[all145_incorr.meanRunSpeed]);
% xlim([-10 50])
% title(['145, p=' num2str(p,3)])
% defaultAxesProperties(gca, false)

%% plot reaction times correct vs incorrect

all144_corr = all144([all144.result]~=0); % all trials
all144_incorr = all144([all144.result]==0);

figure
histogram([all144_corr.RT], 'normalization', 'probability','BinWidth',0.1), hold on
histogram([all144_incorr.RT], 'normalization', 'probability','BinWidth',0.1)
plot(median([all144_corr.RT]), 0.15, 'v', 'MarkerFaceColor','b')
plot(median([all144_incorr.RT]), 0.15, 'v', 'MarkerFaceColor','r')
ylabel('Probability')
xlabel('RT')
xlim([-0.1 5])
p = ranksum([all144_corr.RT],[all144_incorr.RT]);
title(['144, p=' num2str(p,3)])
defaultAxesProperties(gca, true)

all145_corr = all145([all145.result]~=0); % all trials
all145_incorr = all145([all145.result]==0);

figure
histogram([all145_corr.RT], 'normalization', 'probability','BinWidth',0.1), hold on
histogram([all145_incorr.RT], 'normalization', 'probability','BinWidth',0.1)
plot(median([all145_corr.RT]), 0.15, 'v', 'MarkerFaceColor','b')
plot(median([all145_incorr.RT]), 0.15, 'v', 'MarkerFaceColor','r')
ylabel('Probability')
xlabel('RT')
p = ranksum([all145_corr.RT],[all145_incorr.RT]);
xlim([-0.1 5])
title(['145, p=' num2str(p,3)])
defaultAxesProperties(gca, true)

%% do RTs vary with difficulty? for correct responses

easy = all144([all144_corr.absRatio]>2);
hard = all144([all144_corr.absRatio]<=2);
median([easy.RT])
median([hard.RT])

figure, hold on
histogram([easy.RT], 'BinWidth', 0.1,'normalization', 'probability')
histogram([hard.RT], 'BinWidth', 0.1,'normalization', 'probability')
plot(median([easy.RT]), 0.15, 'bv') 
plot(median([hard.RT]), 0.15, 'rv') 
p144 = ranksum([easy.RT], [hard.RT]);
title('m144 - easy vs hard')
ylabel('Probability')

defaultAxesProperties(gca, true)


easy = all145([all145_corr.absRatio]>2);
hard = all145([all145_corr.absRatio]<=2);

figure, hold on
histogram([easy.RT], 'BinWidth', 0.1, 'normalization', 'probability')
histogram([hard.RT], 'BinWidth', 0.1, 'normalization', 'probability')
plot(median([easy.RT]), 0.15, 'bv') 
plot(median([hard.RT]), 0.15, 'rv') 
p145 = ranksum([easy.RT], [hard.RT]);
title('m145 - easy vs hard')
ylabel('Probability')

defaultAxesProperties(gca, true)


% Interestingly RTs were on average slightly quicker than for easy vs hard trials however
% this difference was not sgnificant. Thus, RTs did not vary with task difficulty (easy vs hard p > 0.05 for both
% animals). This was true when task difficulty was split into further
% subgroups (one for each speed ratio, kruskal-wallis tests, p> 0.05).
% compulsive licking (which would be 50% correct if genuinely independet of
% stimulus) also complicates this analysis.



%% stat vs run reaction times (incorrect and correct)

all144_corr = all144([all144.result]~=0); % all trials
all144_incorr = all144([all144.result]==0);
all145_corr = all145([all145.result]~=0); % all trials
all145_incorr = all145([all145.result]==0);

% correct
run144_corr = all144_corr([all144_corr.meanRunSpeed]>=5);
stat144_corr = all144_corr([all144_corr.meanRunSpeed]<=3);

figure, hold on
histogram([stat144_corr.RT],'BinWidth', 0.1,'normalization', 'probability')
hold on
histogram([run144_corr.RT],'BinWidth', 0.1,'normalization', 'probability')
p = ranksum([stat144_corr.RT], [run144_corr.RT])
title('m144, stat vs run, correct')
defaultAxesProperties(gca, true)

run145_corr = all145_corr([all145_corr.meanRunSpeed]>=5);
stat145_corr = all145_corr([all145_corr.meanRunSpeed]<=3);

figure, hold on
histogram([stat145_corr.RT],'BinWidth', 0.1,'normalization', 'probability')
hold on
histogram([run145_corr.RT],'BinWidth', 0.1,'normalization', 'probability')
p = ranksum([stat145_corr.RT], [run145_corr.RT])
title('m145, stat vs run, correct')
defaultAxesProperties(gca, true)

% incorrect
run144_incorr = all144_incorr([all144_incorr.meanRunSpeed]>=5);
stat144_incorr = all144_incorr([all144_incorr.meanRunSpeed]<=3);

figure, hold on
histogram([stat144_incorr.RT],'BinWidth', 0.1,'normalization', 'probability')
hold on
histogram([run144_incorr.RT],'BinWidth', 0.1,'normalization', 'probability')
p = ranksum([stat144_incorr.RT], [run144_incorr.RT])
title('m144, stat vs run, incorrect')
defaultAxesProperties(gca, true)

run145_incorr = all145_incorr([all145_incorr.meanRunSpeed]>=5);
stat145_incorr = all145_incorr([all145_incorr.meanRunSpeed]<=3);

figure, hold on
histogram([stat145_incorr.RT],'BinWidth', 0.1,'normalization', 'probability')
hold on
histogram([run145_incorr.RT],'BinWidth', 0.1,'normalization', 'probability')
p = ranksum([stat145_incorr.RT], [run145_incorr.RT])
title('m145, stat vs run, incorrect')
defaultAxesProperties(gca, true)

%%
% options for signed psychometric curves
options             = struct;   % initialize as an empty struct
options.sigmoidName = 'gauss'; %'rgumbel'   % choose a cumulative Gaussian as the sigmoid
options.expType     = 'YesNo';

% options for absolute value psychometric curve
options             = struct;   % initialize as an empty struct
options2.sigmoidName = 'gauss'; %'rgumbel'   % choose a cumulative Gaussian as the sigmoid
options2.expType     = '2AFC';
options2.poolxTol = 0.1;
options2.poolMaxGap = inf;
options2.poolMaxLength = inf;
options2.nblocks = 1;

for isesh = 1:4
    t = d144trials((end-4)+isesh).trials;
    t = t([t.meanRunSpeed]>=3);
    d144(isesh).speed = plotPsychSDRatio(t, options, options2)
end

for isesh = 1:4
    t = d145trials((end-4)+isesh).trials;
    t = t([t.meanRunSpeed]>=3);
    d145(isesh).speed = plotPsychSDRatio(t, options, options2)
end

alld144=[];
alld145=[];
for isesh = 1:4
    alld144 = vertcat(alld144, [d144(isesh).speed.t70]);
    alld145 = vertcat(alld145, [d145(isesh).speed.t70]);
end

%
figure
errorbar(1:4, mean(alld144), sem(alld144))
hold on
errorbar(1:4, mean(alld145), sem(alld145))



%% visual speed conversion

cols = {'b', 'r', 'g', 'y'};
icol=0;
figure, hold on
for speed = 100:100:400
    icol=icol+1;
    w_deg1 = linv2angv(speed,100,-90:-20);
    w_deg2 = linv2angv(speed,100,20:90);
    
    plot(-90:-20, w_deg1, cols{icol})
    plot(20:90, w_deg2, cols{icol})
end

    

