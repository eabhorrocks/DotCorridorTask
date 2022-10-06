using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;
using System.Reactive;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class ProcessMetaData_SpeedDiscrimination
{
    public IObservable<int> Process(IObservable<float[]> source)
    {
        return source.Select(value => 
        {
            Console.WriteLine(value.Rank());



        return (int) 1;

        });
    }
}
