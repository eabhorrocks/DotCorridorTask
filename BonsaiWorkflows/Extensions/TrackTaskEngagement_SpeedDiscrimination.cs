using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class TrackTaskEngagement_SpeedDiscrimination
{
    public List<int> trialResponses { get; set;} // list of trial responses
    public int maxListLength {get; set; } // 
    public IObservable<double> Process(IObservable<int> source)
    {
        return source.Select(value => 
        {
            trialResponses.Add((int)value);
            if (trialResponses.Count > maxListLength)
            { 
                trialResponses.RemoveAt(0); 
            }

            int count = trialResponses.Count(x => x == 3);
            //Console.WriteLine(count);

            double pEngaged = (double)1 - ((double)count/(double)maxListLength);

            return pEngaged;
        });
    }
}
