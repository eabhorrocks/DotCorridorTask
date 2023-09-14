using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class calcPropInListGreaterThanFloat
{
    public IObservable<float> Process(IObservable<Tuple<List<float>, float>> source)
    {
        return source.Select(value =>
        {
          int nGreaterThan = value.Item1.Count(x => x > value.Item2);

          return (float)nGreaterThan/(float)value.Item1.Count();
        });
    }
}
