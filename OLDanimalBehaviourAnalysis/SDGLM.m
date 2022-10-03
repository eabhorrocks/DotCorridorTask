function [b, dev, stats, modelPerf, absSD, ten, ten2, resVec, yfit, yfit2] = SDGLM(trial)

%% generate predictors for GLM

resVec = ones(numel(trial),1);
for i = 1:numel(trial)
    res = trial(i).response;
    SDvec(i) = trial(i).SD;
    if res == 1 % correct left
        correctVec(i) = -1;
        failVec(i) = 0;
        resVec(i) = 0;
    elseif res == 2 % correct right
        correctVec(i) = 1;
        failVec(i) = 0;
        resVec(i) = 1;
    elseif res == 0 % wrong response
        if SDvec(i) > 0 % stim was right
            correctVec(i) = 0;
            failVec(i) = -1; % incorrect, left lick
            resVec(i) = 0;
        elseif SDvec(i) < 0 % left
            correctVec(i) = 0;
            failVec(i) = 1; % incorrect, right lick
            resVec(i) = 1;
        end
    elseif res == 3
        correctVec(i) = 0;
        failVec(i) = 0;
        resVec(i) = 0;
    end
end

absSD = unique(abs(SDvec));
SDarray = zeros(numel(absSD), size(failVec,2));

for i = 1:numel(trial)
    idx = find(absSD==abs(SDvec(i)));
    if SDvec(i) > 0
        SDarray(idx, i) = 1;
    elseif SDvec(i) < 0
        SDarray(idx,i) = -1;
    end
end

% cant get prediction for trial 1; cant use last correct/fail as nothing to
% predict
resVec(1) = [];
SDarray(:,1) = [];
correctVec(end) = [];
failVec(end) = [];

inputMatrixforGLM = [correctVec; failVec; SDarray]';

[b, dev, stats] = glmfit(inputMatrixforGLM, resVec, 'binomial');
yfit = glmval(b,inputMatrixforGLM,'probit');
yfit2 = zeros(size(yfit));

%yfit2(yfit<0.5) = 0;
%yfit2(yfit>=0.6) = 1;
for i = 1:numel(yfit)
    yfit2(i) = binornd(1,yfit(i));
end

% get CIs for bernoulli simulation

modelPerf.pCorrect = sum(yfit2==resVec)./numel(resVec);


glcoridx = find(yfit2==resVec);
glincoridx = find(yfit2~=resVec);

modelPerf.glcor_meanP = mean(yfit(glcoridx));
modelPerf.glcor_sem = std(yfit(glcoridx))/numel((yfit(glcoridx)));
modelPerf.glincor_meanP = mean(yfit(glincoridx));
modelPerf.glincor_sem = std(yfit(glincoridx))/numel((yfit(glincoridx)));

yfit2 = [NaN; yfit2];

%% tendency - organise with programmatic tags/struct
% now need to work out tendency for the GLM models.
% went left / went right
% rewarded / unrewarded
trialTags = {'leftC', 'leftI', 'rightC', 'rightI'};

ten.leftC.idx = find(([trial.response]==1) & [trial.SD] <0);
ten.leftI.idx = find(([trial.response]==0) & [trial.SD] <0);
ten.rightC.idx =find(([trial.response]==2) & [trial.SD] >0);
ten.rightI.idx =find(([trial.response]==0) & [trial.SD] >0);
% 4 base trials. Find all trials of this type, and check the response on
% the


for itype = 1:numel(trialTags)
    ten2.(trialTags{itype}).nLchoice = 0;
    ten2.(trialTags{itype}).nRchoice = 0;
    
    ten.(trialTags{itype}).nValid = 0;
    ten.(trialTags{itype}).nLstim = 0;
    ten.(trialTags{itype}).nRstim = 0;
    ten.(trialTags{itype}).nLchoice = 0;
    ten.(trialTags{itype}).nRchoice = 0;
   
   
    
    
    for i = 1:numel(ten.(trialTags{itype}).idx)
        % check if animal responded
        if ~(ten.(trialTags{itype}).idx(i)+1 > numel(trial)) 
        if ~(trial(ten.(trialTags{itype}).idx(i)+1).response == 3)
            ten.(trialTags{itype}).nValid = ten.(trialTags{itype}).nValid +1;
            
            % check whether next trial was left or right
            if trial(ten.(trialTags{itype}).idx(i)+1).SD < 0 %left
                ten.(trialTags{itype}).nLstim = ten.(trialTags{itype}).nLstim +1;
            elseif trial(ten.(trialTags{itype}).idx(i)+1).SD > 0 %right
                ten.(trialTags{itype}).nRstim = ten.(trialTags{itype}).nRstim +1;
            end
            
            % check if mouse went left on next trial
            if (trial(ten.(trialTags{itype}).idx(i)+1).response==1) || ...
                    (trial(ten.(trialTags{itype}).idx(i)+1).response ==0 && ...
                    trial(ten.(trialTags{itype}).idx(i)+1).SD > 0)
                ten.(trialTags{itype}).nLchoice = ten.(trialTags{itype}).nLchoice + 1;
                % went right
            elseif (trial(ten.(trialTags{itype}).idx(i)+1).response==2) || ...
                    (trial(ten.(trialTags{itype}).idx(i)+1).response==0 && ...
                    trial(ten.(trialTags{itype}).idx(i)+1).SD < 0)
                ten.(trialTags{itype}).nRchoice = ten.(trialTags{itype}).nRchoice + 1;
            end
            
            % check if model went left on next trial
            if (yfit2(ten.(trialTags{itype}).idx(i)+1)==0)
                ten2.(trialTags{itype}).nLchoice = ten2.(trialTags{itype}).nLchoice + 1;
                % went right
            elseif yfit2(ten.(trialTags{itype}).idx(i)+1)==1
                ten2.(trialTags{itype}).nRchoice = ten2.(trialTags{itype}).nRchoice + 1;
            end
            
            ten.(trialTags{itype}).pR = ten.(trialTags{itype}).nRchoice/ten.(trialTags{itype}).nValid;
            ten.(trialTags{itype}).pL = ten.(trialTags{itype}).nLchoice/ten.(trialTags{itype}).nValid;
            ten.(trialTags{itype}).tenR = (ten.(trialTags{itype}).nRchoice / ten.(trialTags{itype}).nRstim) - 1;
            ten.(trialTags{itype}).tenL = (ten.(trialTags{itype}).nLchoice / ten.(trialTags{itype}).nLstim) - 1;
            
            ten2.(trialTags{itype}).pR = ten2.(trialTags{itype}).nRchoice/ten.(trialTags{itype}).nValid;
            ten2.(trialTags{itype}).pL = ten2.(trialTags{itype}).nLchoice/ten.(trialTags{itype}).nValid;
            ten2.(trialTags{itype}).tenR = (ten2.(trialTags{itype}).nRchoice / ten.(trialTags{itype}).nRstim) - 1;
            ten2.(trialTags{itype}).tenL = (ten2.(trialTags{itype}).nLchoice / ten.(trialTags{itype}).nLstim) - 1;
        end
        end
    end
end


ten.incorrect.stay = (ten.leftI.nLchoice + ten.rightI.nRchoice) / (ten.leftI.nValid + ten.rightI.nValid);
ten.incorrect.switch = (ten.leftI.nRchoice + ten.rightI.nLchoice) / (ten.leftI.nValid + ten.rightI.nValid);
ten.correct.stay = (ten.leftC.nLchoice + ten.rightC.nRchoice) / (ten.leftC.nValid + ten.rightC.nValid);
ten.correct.switch = (ten.leftC.nRchoice + ten.rightC.nLchoice) / (ten.leftC.nValid + ten.rightC.nValid);

ten2.incorrect.stay = (ten2.leftI.nLchoice + ten2.rightI.nRchoice) / (ten.leftI.nValid + ten.rightI.nValid);
ten2.incorrect.switch = (ten2.leftI.nRchoice + ten2.rightI.nLchoice) / (ten.leftI.nValid + ten.rightI.nValid);
ten2.correct.stay = (ten2.leftC.nLchoice + ten2.rightC.nRchoice) / (ten.leftC.nValid + ten.rightC.nValid);
ten2.correct.switch = (ten2.leftC.nRchoice + ten2.rightC.nLchoice) / (ten.leftC.nValid + ten.rightC.nValid);



ten.array = ...
    [ten.leftC.tenL, ten.leftC.tenR;...
    ten.rightC.tenL, ten.rightC.tenR;...
    ten.leftI.tenL, ten.leftI.tenR;...
    ten.rightI.tenL, ten.rightI.tenR];

ten2.array = ...
    [ten2.leftC.tenL, ten2.leftC.tenR;...
    ten2.rightC.tenL, ten2.rightC.tenR;...
    ten2.leftI.tenL, ten2.leftI.tenR;...
    ten2.rightI.tenL, ten2.rightI.tenR];


% %% tendency for the model
% 
% for itype = 1:numel(trialTags)
%     ten2.(trialTags{itype}).nRchoice = 0;
%     ten2.(trialTags{itype}).nLchoice = 0;
%     ten2.(trialTags{itype}).nValid = 0;
%     ten2.(trialTags{itype}).nLstim = 0;
%     ten2.(trialTags{itype}).nRstim = 0;
%     
%     
%     for i = 1:numel(ten.(trialTags{itype}).idx)
%         if ~(trial(ten.(trialTags{itype}).idx(i)+1).response == 3)
%             ten2.(trialTags{itype}).nValid = ten2.(trialTags{itype}).nValid +1;
%             
%             % check whether next trial was left or right
%             if trial(ten.(trialTags{itype}).idx(i)+1).SD < 0
%                 ten2.(trialTags{itype}).nLstim = ten2.(trialTags{itype}).nLstim +1;
%             elseif trial(ten.(trialTags{itype}).idx(i)+1).SD > 0
%                 ten2.(trialTags{itype}).nRstim = ten2.(trialTags{itype}).nRstim +1;
%             end
%             
%             % check if went left
%             if (yfit2(ten.(trialTags{itype}).idx(i)+1)==0)
%                 ten2.(trialTags{itype}).nLchoice = ten2.(trialTags{itype}).nLchoice + 1;
%                 % went right
%             elseif yfit2(ten.(trialTags{itype}).idx(i)+1)==1
%                 ten2.(trialTags{itype}).nRchoice = ten2.(trialTags{itype}).nRchoice + 1;
%             end
%         end
%         ten2.(trialTags{itype}).pR = ten2.(trialTags{itype}).nRchoice/ten2.(trialTags{itype}).nValid;
%         ten2.(trialTags{itype}).pL = ten2.(trialTags{itype}).nLchoice/ten2.(trialTags{itype}).nValid;
%         ten2.(trialTags{itype}).tenR = (ten2.(trialTags{itype}).nRchoice / ten2.(trialTags{itype}).nRstim) - 1;
%         ten2.(trialTags{itype}).tenL = (ten2.(trialTags{itype}).nLchoice / ten2.(trialTags{itype}).nLstim) - 1;
%     end
% end
% 
% 
% ten2.incorrect.stay = (ten2.leftI.nLchoice + ten2.rightI.nRchoice) / (ten2.leftI.nValid + ten2.rightI.nValid);
% ten2.incorrect.switch = (ten2.leftI.nRchoice + ten2.rightI.nLchoice) / (ten2.leftI.nValid + ten2.rightI.nValid);
% ten2.correct.stay = (ten2.leftC.nLchoice + ten2.rightC.nRchoice) / (ten2.leftC.nValid + ten2.rightC.nValid);
% ten2.correct.switch = (ten2.leftC.nRchoice + ten2.rightC.nLchoice) / (ten2.leftC.nValid + ten2.rightC.nValid);
% 
% ten2.array = ...
%     [ten2.leftC.tenL, ten2.leftC.tenR;...
%     ten2.rightC.tenL, ten2.rightC.tenR;...
%     ten2.leftI.tenL, ten2.leftI.tenR;...
%     ten2.rightI.tenL, ten2.rightI.tenR];
% 
% 

%% plots

%
fh = figure;
h(1) = subplot(2,4,[1 2 5 6]);
errorbar(absSD, stats.beta(end-(numel(absSD)-1):end), stats.se(end-(numel(absSD)-1):end),...
    'o','LineStyle','None', 'MarkerFaceColor', 'k','Color', 'k')
box off
xlim([0, max(absSD)+10])
hold on,
am = max(absSD);
errorbar([am+7, am+8, am+9], stats.beta(1:3), stats.se(1:3), 'o',...
    'LineStyle', 'None','MarkerFaceColor', 'k', 'Color', 'k')
%ylim([-.5, 2.5])
plot([0 max(absSD)+10], [0 0], 'k--')
ylabel('Weights','FontSize',18)
a = gca;
a.FontSize = 18;
a.XTick = [0, absSD, am+7, am+8, am+9];
a.XTickLabels(end-2) = {'b_0'};
a.XTickLabels(end-1) = {'b_s'};
a.XTickLabels(end) = {'b_f'};
xlabel('Speed Differences','FontSize',18)

%significance markers... if p <, text = '*', else if p <, text = '**'....

%b0 pval
pval = stats.p(1); xval = am+7;
if  pval <0.001, sigtext = '***'; elseif pval < 0.01, sigtext = '**'; elseif pval <= 0.05 sigtext = '*';
elseif pval > 0.05, sigtext = 'n.s.'; end
text(xval, stats.beta(1)+stats.se(1)+0.1, sigtext, 'FontSize',18,'HorizontalAlignment','center')

pval = stats.p(2); xval = am+8;
if  pval <0.001, sigtext = '***'; elseif pval < 0.01, sigtext = '**'; elseif pval <= 0.05 sigtext = '*';
elseif pval > 0.05, sigtext = 'n.s.'; end
text(xval, stats.beta(2)+stats.se(2)+0.1, sigtext, 'FontSize',18,'HorizontalAlignment','center')

pval = stats.p(3); xval = am+9;
if  pval <0.001, sigtext = '***'; elseif pval < 0.01, sigtext = '**'; elseif pval <= 0.05 sigtext = '*';
elseif pval > 0.05, sigtext = 'n.s.'; end
text(xval, stats.beta(3)+stats.se(3)+0.1, sigtext, 'FontSize',18,'HorizontalAlignment','center')

for istim = 1:numel(absSD)
    pval = stats.p(3+istim); xval = absSD(istim);
if  pval <0.001, sigtext = '***'; elseif pval < 0.01, sigtext = '**'; elseif pval <= 0.05 sigtext = '*';
elseif pval > 0.05, sigtext = 'n.s.'; end
text(xval, stats.beta(3+istim)+stats.se(3+istim)+0.1, sigtext, 'FontSize',18,'HorizontalAlignment','center')
    
end
%text(absSD(1)-0.1, stats.beta(end-(numel(absSD)-1))+stats.se(end-(numel(absSD)-1))+0.1, '*','FontSize',18)
%horizontal alignment = center..

% imagesc plots

maxVal = max(max(abs(ten.array)));
maxVal2 = max(max(abs(ten2.array)));
maxValAll = max([maxVal, maxVal2]);
%[stats.beta, stats.se];

% mouse
h(2) = subplot(2,4,3);
imagesc(ten.array(1:2,:));
title('Mouse', 'FontSize', 16)
a = gca;
a.FontSize = 16;
a.YTick = [1 2];
a.YTickLabels = {'L', 'R'};
a.YLabel.String = 'Past success';
a.YLabel.FontSize = 18;
a.XTick = [];
caxis([-maxValAll maxValAll]);

h(3) = subplot(2,4,7);
imagesc(ten.array(3:4,:))
a = gca;
a.FontSize = 16;
a.YTick = [1 2];
a.YTickLabels = {'L', 'R'};
a.YLabel.String = 'Past failure';
a.YLabel.FontSize = 18;
a.XTick = [1 2];
a.XTickLabels = {'L', 'R'};
xlabel('Present choice', 'FontSize', 18)



% model
h(4) = subplot(2,4,4);
imagesc(ten2.array(1:2,:));
title('Full Model', 'FontSize', 16)
caxis([-maxValAll maxValAll]);
a = gca;
a.XTick = [];
a.YTick = [];


h(5) = subplot(2,4,8);
imagesc(ten2.array(3:4,:))
colormap(gray);
caxis([-maxValAll maxValAll]);
a = gca;
a.XTick = [];
a.YTick = [];

cb = colorbar;
cb.Position = [0.922420634920636,0.102708803611738,0.01329365079365,0.820207863054927];
cb.Title.String = 'Tendency';
cb.Title.FontSize = 14;
