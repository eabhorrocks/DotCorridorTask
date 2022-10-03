function speed = plotPsychSDRatio_RunvsStat(statTrials, runTrials, options)

meanSpeeds = unique([runTrials.geoMean]);
for ispeed = 1:numel(meanSpeeds)
    figure, hold on
    
    % stat trials

    speed(ispeed).meanSpeed = meanSpeeds(ispeed);
    speed(ispeed).ratios = [];
    speed(ispeed).trials = ...
    statTrials(find([statTrials.geoMean]==meanSpeeds(ispeed)));
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
    
    speed(ispeed).psigResult = psignifit(speed(ispeed).psigMatrix, options);
     
     plotOptions.lineColor = [1 0 0];
     plotOptions.plotData = 0;     
     plotOptions.plotAsymptote = false;
     plotOptions.plotThresh = false;
     plotOptions.extrapolLength = 0;

     plotPsych(speed(ispeed).psigResult, plotOptions);
     
     
     % run trials
     speed(ispeed).meanSpeed = meanSpeeds(ispeed);
    speed(ispeed).ratios = [];
    speed(ispeed).trials = ...
    runTrials(find([runTrials.geoMean]==meanSpeeds(ispeed)));
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
    
    speed(ispeed).psigResult = psignifit(speed(ispeed).psigMatrix, options);
     
     plotOptions.lineColor = [0 1 0];
     plotOptions.plotData = 0;
     plotPsych(speed(ispeed).psigResult, plotOptions);
    
     title(['Speed: ' num2str(speed(ispeed).meanSpeed)]);
         


end
