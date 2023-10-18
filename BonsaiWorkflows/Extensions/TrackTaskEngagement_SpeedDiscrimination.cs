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
    public double pEngagedThreshold {get; set; }
    public IObservable<Tuple<bool, double>> Process(IObservable<int> source)
    {
        return source.Select(value => 
        {
            trialResponses.Add((int)value);
            while (trialResponses.Count > maxListLength)
            { 
                trialResponses.RemoveAt(0); 
            }

            int count = trialResponses.Count(x => x == 3);

            // calculate fraction of trials the mouse has responded to
            double pEngaged = (double)1 - ((double)count/(double)maxListLength);
            Console.WriteLine("Engagement N" + trialResponses.Count + "nDis" + count + "pEng" + pEngaged);


            // if below the threshold, set output to true and reset the list, otherwise set output as false
            var engagedbool = false;
            if (pEngaged <= pEngagedThreshold) 
            {
                engagedbool = true;
                trialResponses = new List<int>(Enumerable.Repeat(0, maxListLength));
            }

            var output = Tuple.Create(engagedbool, pEngaged);

            return output;
        });
    }
}
