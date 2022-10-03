%% GLME analysis for stationary vs running performance in mouse SD task

load('M144_day_261121.mat');
day144 = day;
m144_trials = [day(end-3:end).trials];


load('M145_lastday_261121.mat')
day145 = day;
m145_trials = [day(end-4:end).trials];

%% generate table


subject = repelem({'m144', 'm145'}, [numel(m144_trials), numel(m145_trials)]);
subject = subject(:);

meanSpeed = categorical(vertcat(vertcat(m144_trials.geoMean), vertcat(m145_trials.geoMean)));
geoRatio = exp(abs(log(vertcat(vertcat(m144_trials.geoRatio), vertcat(m145_trials.geoRatio)))));
correct = vertcat(vertcat(m144_trials.result)~=0, vertcat(m145_trials.result)~=0);

tbl = table(correct(:), meanSpeed(:), geoRatio(:), subject(:), 'VariableNames', {'correct', 'meanSpeed', 'geoRatio', 'subject'});

formula = 'correct ~ -1 + meanSpeed + (1 + geoRatio | subject)';

glme_speed = fitglme(tbl, formula, 'DummyVarCoding', 'full')

