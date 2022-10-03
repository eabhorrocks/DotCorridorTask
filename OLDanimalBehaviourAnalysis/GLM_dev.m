%% edd glm model dev

% what are the predictors?
% speed difference (indicator matrix)
% success on previous trial (-1, 0 or 1)
% failure on previous trial (-1, 0 or 1)
% ^^^^ if one is non-zero the other must be 0, both can be 0 for aborted
% trials.

% fit model using glmfit

% first row is a constant, to estimate b0 (bias)
% 2nd was was sequence s(t) shifted by one trial (success on prev trial)
% 3rd row was f(t) shifted by one trial (failure on previous trial)

% Remaining rows were used for absolute speed differences. One for each
% absolute value:
% 1 if SD was +ve, -1 if SD was -ve. Allows estimation of the weights for
% each possible value.

% res = 1 correct left, res = 2 correct right, res = 3 correct 0
% if SD > 0, 


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
        if SDvec(i) > 0 % right
            correctVec(i) = 0;
            failVec(i) = -1;
            resVec(i) = 0; 
        elseif SDvec(i) < 0 % left
            correctVec(i) = 0;
            failVec(i) = 1;
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
resVec = resVec;
SDarray(:,1) = [];
correctVec(end) = [];
failVec(end) = [];

constantforbias = 1 * ones(size(failVec));

inputMatrixforGLM = [correctVec; failVec; SDarray]';

[b dev stats] = glmfit(inputMatrixforGLM, resVec, 'binomial');
yfit = glmval(b,inputMatrixforGLM,'probit');
yfit2 = zeros(size(yfit));
yfit2(yfit<0.5) = 0;
yfit2(yfit>=0.6) = 1;

propCorrect = sum(yfit2==resVec)./numel(resVec)


%% tendency
% went left / went right
% rewarded / unrewarded

% 4 base trials. Find all trials of this type, and check the response on
% the
