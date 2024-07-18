using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class TrackPerformance_SD_2024
{
    public List<int> TrialCountsArray {get; set; }
    public List<int> TrialCorrectArray {get; set; }
    public List<int> RightResponseArray {get; set; }

    public IObservable<Tuple<List<int>, List<int>, List<double>>> Process(IObservable<Tuple<float, int, int>> source)
    {
        return source.Select(value => 
        {
            int nSpeedPairs = TrialCountsArray.Count();
            float response = value.Item1;
            int trialResult = value.Item2;
            int speedPairIndex = value.Item3;
            List<double> pCorrectArray = new List<double>();
            Console.WriteLine("index: " + speedPairIndex);
            

            TrialCountsArray[speedPairIndex] = TrialCountsArray[speedPairIndex]+1;
            //Console.WriteLine(TrialCountsArray[speedPairIndex]);

            if (trialResult==1 | trialResult==-1)
            {
                TrialCorrectArray[speedPairIndex]=TrialCorrectArray[speedPairIndex]+1;
                Console.WriteLine(TrialCorrectArray[speedPairIndex]);
            }

            
            Console.WriteLine("pcorr");
            for (int i=0; i<nSpeedPairs; i++)
            {
                double nCorrect = (double)TrialCorrectArray[i];
                double nCount = (double)TrialCountsArray[i];
                double pCorrect = nCorrect/nCount;
                pCorrectArray.Add(pCorrect);
                Console.WriteLine("ncorr: " + nCorrect + " nCount: " + nCount + " pCorr" + pCorrect);

            }

            

            var output = new Tuple<List<int>, List<int>, List<double>>(TrialCountsArray, TrialCorrectArray, pCorrectArray);

            return output;

             
        }
        );
    }
}
