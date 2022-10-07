using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class PrependFloatToList
{
    public IObservable<List<float>> Process(IObservable<Tuple<List<float>, float>> source)
    {
        return source.Select(value => 
        {
            var output = new List<float>(value.Item1);
            output.Insert(0, value.Item2);

            return output;
        });
    }
}
