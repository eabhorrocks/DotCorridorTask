function speed = plotPOPPsychSDRatioAllTrials(trialsStructArray, options)

trialsStructArray(end+1).trials = [trialsStructArray.trials];
figure
hold on



for i = 1:numel(trialsStructArray)
        ispeed=1;
    validTrials = trialsStructArray(i).trials;
    speed(ispeed).ratios = [];
    speed(ispeed).trials = validTrials;
    speed(ispeed).ratios = unique([speed(ispeed).trials.geoRatio]);
    speed(ispeed).psigMatrix = [];
    
    for iratio = 1:numel(speed(ispeed).ratios)
        speed(ispeed).ratTrials(iratio).trials = ...
            speed(ispeed).trials(find([speed(ispeed).trials.geoRatio]==speed(ispeed).ratios(iratio)));
        
        
        speed(ispeed).psigMatrix(iratio,1) = log(speed(ispeed).ratios(iratio));
%         if speed(ispeed).psigMatrix(iratio,1) < 1
%             speed(ispeed).psigMatrix(iratio,1) = -(1/speed(ispeed).psigMatrix(iratio,1));
%         end
       
        speed(ispeed).psigMatrix(iratio,2) = numel(find([speed(ispeed).ratTrials(iratio).trials.response]==1));
        speed(ispeed).psigMatrix(iratio,3) = numel([speed(ispeed).ratTrials(iratio).trials]);
    end
    plotOptions.plotData = 0;
    if i ~= numel(trialsStructArray)
    plotOptions.lineColor = [.7 .7 .7];
    else
        plotOptions.lineColor = [0 0 0];
    end
    speed(ispeed).psigResult = psignifit(speed(ispeed).psigMatrix, options);
     plotPsych(speed(ispeed).psigResult, plotOptions);
    % title(['Speed: ' num2str(speed(ispeed).meanSpeed)]);
    
end

% hold off
% options = options2;
% 
% for ispeed = 1:numel(meanSpeeds)
%     for iratio = 1:numel(speed(ispeed).ratios)
%         speed(ispeed).abspsigMatrix(iratio,1) = abs(speed(ispeed).psigMatrix(iratio,1));
%         speed(ispeed).abspsigMatrix(iratio,2) = numel(find([speed(ispeed).ratTrials(iratio).trials.result]~=0));
%         speed(ispeed).abspsigMatrix(iratio,3) = numel([speed(ispeed).ratTrials(iratio).trials]);
%     end
%     
%     
%     speed(ispeed).abspsigResult = psignifit(speed(ispeed).abspsigMatrix,options);
%      figure
%      plotPsych(speed(ispeed).abspsigResult);
%      title(['(abs) Speed: ' num2str(speed(ispeed).meanSpeed)])
%     
%     speed(ispeed).t50 = getThreshold(speed(ispeed).psigResult, 0.5, true);
%     speed(ispeed).t70 = getThreshold(speed(ispeed).abspsigResult, 0.7, true);
%     
%     
% end