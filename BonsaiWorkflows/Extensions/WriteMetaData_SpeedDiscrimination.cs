using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class WriteMetaData_SpeedDiscrimination
{
    public List<float> StandardSpeedsList {get; set; }
    public List<float> StandardSpeedsProbList {get; set; }
    public List<List<float>> SpeedDifferenceList {get; set; }  
    public List<List<float>> SpeedDifferenceProbList {get; set; }  
    public IObservable<List<float>> Process(IObservable<int> source)
    {
        return source.Select(value => 
        {
            List<float> output = new List<float>();

            output.Add(SpeedDifferenceList[0][value]);
            Console.WriteLine(24);
            for (int iSpeed=0; iSpeed<StandardSpeedsList.Count(); iSpeed++)
            {
                Console.WriteLine(iSpeed);
                output.Add(SpeedDifferenceProbList[iSpeed][value]);
            }

            return output;
        });
    }
}
