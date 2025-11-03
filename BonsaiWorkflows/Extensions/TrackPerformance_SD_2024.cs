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
    public List<int> TrialCountsList {get; set; }
    public List<int> TrialCorrectList {get; set; }
    public List<int> RightResponseList {get; set; }
    public List<int> TrialEngagedList {get; set; }

    public IObservable<Tuple<List<int>, List<int>, List<double>, List<double>>> Process(IObservable<Tuple<float, int, int>> source)
    {
        return source.Select(value => 
        {
            int nSpeedPairs = TrialCountsList.Count();
            float response = value.Item1;
            int trialResult = value.Item2;
            int speedPairIndex = value.Item3;
            List<double> pCorrectList = new List<double>();
            List<double> pEngagedList = new List<double>();

            //Console.WriteLine("index: " + speedPairIndex);
            
            
            TrialCountsList[speedPairIndex] = TrialCountsList[speedPairIndex]+1;
            //Console.WriteLine(TrialCountsArray[speedPairIndex]);

            if (trialResult==1 | trialResult==-1)
            {
                TrialCorrectList[speedPairIndex]=TrialCorrectList[speedPairIndex]+1;
                //Console.WriteLine(TrialCorrectList[speedPairIndex]);
            }

            if (trialResult!=3)
            {
                TrialEngagedList[speedPairIndex]=TrialEngagedList[speedPairIndex]+1;
            }

            
            //Console.WriteLine("pcorr");
            for (int i=0; i<nSpeedPairs; i++)
            {
                double nCorrect = (double)TrialCorrectList[i];
                double nCount = (double)TrialCountsList[i];
                double nEngaged = (double)TrialEngagedList[i];
                double pCorrect = nCorrect/nCount;
                double pEngaged = nEngaged/nCount;

                pCorrectList.Add(pCorrect);
                pEngagedList.Add(pEngaged);
                //Console.WriteLine("ncorr: " + nCorrect + " nCount: " + nCount + " pCorr" + pCorrect);

            }

            

            var output = new Tuple<List<int>, List<int>, List<double>, List<double>>(TrialCountsList, TrialCorrectList, pCorrectList, pEngagedList);

            return output;

             
        }
        );
    }
}
