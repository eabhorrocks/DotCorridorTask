using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;
using OpenTK;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class ComputeTrialResult_SpeedDiscrimination
{    
    public List<List<int[]>> perfTracking {get; set; }
    //<Tuple<Tuple<double, double>, Tuple<float, int, int, int>, float>
    
        public IObservable<Tuple<List<List<int[]>>,int>> Process(IObservable<Tuple<Tuple<int, int, int, int>, float>> source)
    {
        return source.Select(value => 
        {
            //left speed, right speed, mean speed, ratioIndex, left/right -1/1, nRatios
            Tuple<int, int, int, int> otherInfo = value.Item1;
            int standardSpeedIndex = otherInfo.Item1;
            int speedDifferenceIndex = otherInfo.Item2;
            int rightFaster = otherInfo.Item3;
            int nSpeedDiffs = otherInfo.Item4;
            
            float response = value.Item2;


            //Console.WriteLine("response: " + response);
            // if mouse responded, increment n trials for left/right at that ratio.
            // if mouse was also correct, increment total correct trials for left/right at that ratio
            int trialOutcome = 3; // assume no response by default
            if (response != 0)
            {
                if (rightFaster==1) //right faster
                {   trialOutcome = 0; // assume incorrect
                    perfTracking[standardSpeedIndex][speedDifferenceIndex][0]++;
                    if (response == 1) // response was right
                    {
                        perfTracking[standardSpeedIndex][speedDifferenceIndex][1]++;
                        trialOutcome = 2; // correct right response
                    }
                }
                else if (rightFaster==-1) //left faster
                {   trialOutcome = 0; // assume incorrect
                    perfTracking[standardSpeedIndex][speedDifferenceIndex][2]++;
                    if (response == -1)
                    {
                    perfTracking[standardSpeedIndex][speedDifferenceIndex][3]++;
                    trialOutcome = 1; //correct left response
                    }
                }
            }

            //Console.WriteLine(perfTracking[meanSpeedIndex][ratioIndex][0]);
            //Console.WriteLine(perfTracking[meanSpeedIndex][ratioIndex][1]);
            //Console.WriteLine(perfTracking[meanSpeedIndex][ratioIndex][2]);
            //Console.WriteLine(perfTracking[meanSpeedIndex][ratioIndex][3]);

            // trial outcomes (int)
            // 0: incorrect, 1: left correct, 2: right correct, 3: no response
            var result = new Tuple<List<List<int[]>>,int>(perfTracking,trialOutcome);
            return result;

        });
    }
}
