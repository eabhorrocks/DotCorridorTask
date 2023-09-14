using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Source)]
public class CreateEmptyFloatList
{
    public IObservable<List<float>> Process()
    {
        List<float> output = new List<float>();
        return Observable.Return(output);
    }
}
