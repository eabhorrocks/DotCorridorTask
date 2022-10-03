using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Source)]
public class InitialisePerformanceTracking_SpeedDiscrimination
{
    public float StandardSpeed {get; set; }
    public List<float> SpeedDifferences {get; set; }  
    public List<float> SpeedDifferenceProbs {get; set; }  
    public IObservable<Tuple<List<float>, List<float>, List<int[]>, float>> Process()
    {

        int nSpeedDiffs = SpeedDifferences.Count();

        List<int[]> PerformanceTracking = new List<int[]>();

        for (int i=0; i<nSpeedDiffs; i++)
        {
            int[] p1 = new int[4] {0,  0,  0,  0};
            PerformanceTracking.Add(p1);

        }


        var output = Tuple.Create(SpeedDifferences, SpeedDifferenceProbs, PerformanceTracking, StandardSpeed);
        return Observable.Return(output);
    }
}
