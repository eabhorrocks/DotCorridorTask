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
public class TrialManager_SD_2024
{
    // Externalised properties
    public float[][] SpeedPairsArray {get; set;} // 
    // first index accesses arrays for Speed1,Speed2,SpeedPairProb
    // second index accesses the specific speed pair

    public int itrial {get; set; }

    // left/right properties
    public List<int> rightInARow {get; set; } //
    public int maxInARow {get; set; }
    //public bool autoBias {get; set; }
    //public float biasScaling {get; set; }
    public float pRightManual {get; set; }
    //public float minPRight {get; set; }


    public IObservable<Tuple<Tuple<double,double>,int,int>> Process(IObservable<Unit> source)
    {
        return source.Select(value =>
        {
            int nSpeedPairs = SpeedPairsArray[0].Count();
            var rng = new Random((int)DateTime.Now.Ticks); // random number generator
            
            float[] SpeedPairProbs = SpeedPairsArray[2];
            int speedPairIndex = new int();

            //float bias = 0f;
            //float totalNorm = 0f;
           
            Tuple<double,double> speeds2show;

            ///// Pick speed pair to test /////
            int randomSpeedPair = rng.Next(101); // random number between 1 and 100
            for (int i=0; i<nSpeedPairs; i++) // loop through speed pair
            {
                float sum = SpeedPairProbs.Take(i+1).Sum(); // take cumulative sum of i+1 elements in standardSpeed probs 
                if (randomSpeedPair <= sum) // if the sum is more than the random number, choose it
                {
                    speedPairIndex = i; // index of the standard speed to be tested
                    break;
                }
            }
            
            
            float Speed1 = SpeedPairsArray[0][speedPairIndex];
            float Speed2 = SpeedPairsArray[1][speedPairIndex];
            
            if (Speed1 > Speed2) // make speed2 always faster than speed1
            {
                float tempSpeed2 = Speed1;
                Speed1 = Speed2;
                Speed2 = tempSpeed2;
            }


            ///// Choose whether left or right is faster /////
            // if first trials/error, revert to manual setting
            //if (Single.IsNaN(pRight)) {pRight = pRightManual;}
            float pRight;
            int rightFaster = 1;
            pRight = pRightManual;
            // now use random number to choose whether left or right is faster
            float biasrnd = (float)rng.NextDouble(); // random number for left / right faster

            // first check if maxInARow trials have just been shown (consecutively all left or all right)
            if (rightInARow.All(x => x == 1)) {biasrnd = 1.1f;} // if list is all rights, next trial must be left
            if (rightInARow.All(x => x == -1)){biasrnd = -0.1f;} // if list is all lefts, next trial must be right
            
            if (biasrnd <= pRight) // compare to pre-calculated pRight value (probability of right faster)
            {
            rightFaster = 1; 
            speeds2show = new Tuple<double,double>(Speed1,Speed2);
            }
            else // if biasrnd>pRight
            {
            rightFaster = -1; // left is faster
            speeds2show = new Tuple<double,double>(Speed2,Speed1);
            }

            // add right faster, remove first elements from list if needed
            rightInARow.Add(rightFaster);
            while (rightInARow.Count > maxInARow) { rightInARow.RemoveAt(0); }
            
            //for (int i=0; i<rightInARow.Count; i++) {Console.WriteLine(rightInARow[i]);}

            var output = Tuple.Create(speeds2show,rightFaster,speedPairIndex);
            return output;
        });
    }
}
