using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class angv2liv
{
    public double AngleFromCentreDeg { get; set; }
    public double xDistance { get; set; }

    public IObservable<double> Process(IObservable<double> source)
    {
        return source.Select(value => 
        {
            double dthetadeg = value;
            double dthetarad = dthetadeg*(Math.PI/180);
            //double dist=100;
            //double AngleFromCentreDeg = 60;

            double theta = 90-AngleFromCentreDeg; // convert to angle from the side
            double theta_rad = theta * (Math.PI/180); // convert to radians

            double linv = (xDistance/(Math.Pow(Math.Cos(theta_rad),2)))*dthetarad;
            // dx/dt = y/cos^2(theta) * dtheta/dt;

           

            return linv;

        });
    }
}
