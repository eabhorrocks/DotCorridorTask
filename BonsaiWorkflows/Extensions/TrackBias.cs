using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class TrackBias
{
    public List<int> trialResponseList{ get; set; } // list of trial responses
    public List<int> trialResultsList { get; set; }
    public IObservable<Tuple<List<int>, List<int>>> Process(IObservable<Tuple<int, int>> source)
    {
        return source.Select(value =>
        {
            int trialResult = value.Item1;
            int trialResponse = value.Item2;

            // insert latest values at top of lists
            trialResultsList.Insert(0, trialResult);
            trialResponseList.Insert(0, trialResponse);
        
            return Tuple.Create(trialResultsList, trialResponseList);
        });
    }
}
