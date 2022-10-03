%% psytrack prep data

% bias
% stim left (array, [prev values as well)
% stim right
% speed difference
% average speed? (on last trial?)  prior stim history...
% previous correct answer
% previous choice

% get rid of invalid trials!
function [y, s1, s2, prevAns, prevChoice, correctVec, answerVec] = makePsytrackInputs(trial)

y = [trial.whichlick];
correctVec = zeros(size(y));
correctVec(ismember([trial.response],[1,2]))=1;
choice = [trial.whichlick];
y(y==1)=2;
y(y==-1)=1;

lvel = abs([trial.velXL]);
rvel = abs([trial.velXR]);
maxVel = 10;
s1 = lvel./maxVel;
s2 = rvel./maxVel;
answerVec = [];
answerVec(lvel>rvel)=-1;
answerVec(rvel>lvel)=1;

SDvec = [trial.SD];
SDvec = SDvec'./max(abs([trial.SD]));


prevAns = [NaN, answerVec];
prevChoice = [NaN, choice];
y = [y NaN];
s1 = [s1 NaN];
s2 = [s2 NaN];
answerVec = [answerVec NaN];
choice = [choice NaN];
correctVec = [correctVec NaN];

y = y';
s1 = s1';
s2 = s2';
prevAns = prevAns';
prevChoice = prevChoice';
correctVec = correctVec';

%avSpeed = [lvel+rvel] for now is constant

todel = find(y==0);
todel = [1; todel; numel(y)];

y(todel) = [];
s1(todel)=[];
s2(todel)=[];
prevAns(todel)=[];
prevChoice(todel)=[];
answerVec(todel)=[];
choice(todel)=[];
correctVec(todel)=[];
end
