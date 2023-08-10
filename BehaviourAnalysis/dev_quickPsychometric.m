



filenames = {'X:\ibn-vision\DATA\SUBJECTS\M23002\SDTraining\230322\TrialParams2023-03-22T16_18_07.csv'}

tbl = table;
for ifile = 1:numel(filenames)
    temp_tbl = flexibleTableRead(filenames{ifile});
    tbl = cat(1,tbl,temp_tbl);
end

trialTypes = unique(tbl.TrialType);


uniqueSpeedPairs = unique([tbl.LeftVel, tbl.RightVel],'rows');
uniqueSpeeds = unique(uniqueSpeedPairs(:));
log2us = log2(uniqueSpeeds);

for icond = 1:size(uniqueSpeedPairs,1)
    idx = find([tbl.LeftVel]==uniqueSpeedPairs(icond,1) &...
        [tbl.RightVel]==uniqueSpeedPairs(icond,2) & [tbl.TrialResult]~=3);
    cond(icond).idx = idx;
    cond(icond).nTrials = numel(idx);
    cond(icond).nCorrect = sum(tbl.TrialResult(idx)~=0);
    cond(icond).nIncorrect = sum(tbl.TrialResult(idx)==0);
    cond(icond).pCorrect = cond(icond).nCorrect/cond(icond).nTrials;
    cond(icond).nRight = sum(tbl.Response(idx)==1);
    cond(icond).pRight = cond(icond).nRight/cond(icond).nTrials;
    cond(icond).VelL = tbl.LeftVel(idx(1));
    cond(icond).VelR = tbl.RightVel(idx(1));
    cond(icond).ratio = cond(icond).VelR./cond(icond).VelL;
end

totalTrials = sum([cond.nTrials]);
totalCorrect = sum([cond.nCorrect]);
pCorrect = totalCorrect/totalTrials;



figure
plot(log2([cond.ratio]), [cond.pCorrect], 'o')

figure
plot(log2([cond.ratio]), [cond.pRight], 'o')

% 1 4, 2 6, 3 7, 5, 8
figure, hold on
plot([8 -8], [cond(1).pRight, cond(4).pRight], 'o-');
plot([8 -8], [cond(2).pRight, cond(6).pRight], 'o-');
plot([8 -8], [cond(3).pRight, cond(7).pRight], 'o-');
plot([8 -8], [cond(5).pRight, cond(8).pRight], 'o-');


prr = sum(cat(1,cond([cond.ratio]==8).nRight))/sum(cat(1,cond([cond.ratio]==8).nTrials));
prl = sum(cat(1,cond([cond.ratio]==0.125).nRight))/sum(cat(1,cond([cond.ratio]==0.125).nTrials));


%% 2D plot of speeds
pRArray = nan(numel(uniqueSpeeds));

for ispd1 = 1:numel(uniqueSpeeds)
    for ispd2 = 1:numel(uniqueSpeeds)
        idx = find([cond.VelL]==uniqueSpeeds(ispd1) & [cond.VelR]==uniqueSpeeds(ispd2));
        if ~isempty(idx)
        pRArray(ispd1,ispd2) = cond(idx).pRight;
        end
    end
end

figure
imAlpha=ones(size(pRArray));
imAlpha(isnan(pRArray))=0;
imagesc(pRArray,'AlphaData',imAlpha);
set(gca,'color',0*[1 1 1]);
ax = gca; ax.XTickLabel = uniqueSpeeds; ax.YTickLabel = uniqueSpeeds;
axis xy
ylabel('Left Speed')
xlabel('Right Speed')
cb = colorbar; cb.Label.String = 'P(right)';
caxis([0 1])
colormap(redblue)


