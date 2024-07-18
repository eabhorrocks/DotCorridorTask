using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class ComputeResult_SpeedDiscrim2024
{
    public IObservable<int> Process(IObservable<Tuple<int, float>> source)
    {
        return source.Select(value => 
        {
            int rightFaster = value.Item1;
            float response = value.Item2;
            int trialOutcome = 3; // assume no response by default

            if (response != 0)
            {
                if (rightFaster==1) //right faster
                {   trialOutcome = 0; // assume incorrect
                    if (response == 1) // response was right
                    {
                        trialOutcome = 1; // correct right response
                    }
                }
                else if (rightFaster==-1) //left faster
                {   trialOutcome = 0; // assume incorrect
                    if (response == -1)
                    {
                    trialOutcome = -1; //correct left response
                    }
                }
            }

            return trialOutcome;
            
            


            

            
        });
    }
}
