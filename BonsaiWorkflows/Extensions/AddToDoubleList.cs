using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class AddToFloatList
{
    public List<float> theList {get; set;}
    public IObservable<List<float>> Process(IObservable<float> source)
    {
        return source.Select(value => 
        {
            theList.Insert(0, value);
            return theList;
        });
        
    }
}
