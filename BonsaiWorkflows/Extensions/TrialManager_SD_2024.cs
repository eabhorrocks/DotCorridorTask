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
    public List<int> rightInARow { get; set; } //
    
    public List<int> trialResultsList { get; set; } //
    public List<int> trialResponseList {get; set; } //


    public int maxInARow { get; set; }
    
    public int biasWindow { get; set; }
    public bool autoBias {get; set; }
    public float biasScaling {get; set; }
    public float pRightManual {get; set; }
    public float minPRight {get; set; }


    public IObservable<Tuple<Tuple<double,double>,int,int>> Process(IObservable<Unit> source)
    {
        return source.Select(value =>
        {
            int nSpeedPairs = SpeedPairsArray[0].Count();
            var rng = new Random((int)DateTime.Now.Ticks); // random number generator
            
            float[] SpeedPairProbs = SpeedPairsArray[2];
            int speedPairIndex = new int();

            // use trialResultsList to generate maxInARowList, then trim it to maxInARow length
            List<int> maxInARowList = new List<int>(trialResultsList);
            // if maxInARowList is less than maxInARow, pad end with zeros
            while (maxInARowList.Count < maxInARow) { maxInARowList.Add(0); }
            while (maxInARowList.Count > maxInARow) { maxInARowList.RemoveAt(maxInARowList.Count - 1); }

            // use trialResultsList to generate biasList, then trim it to biasWindow length
            List<int> biasList = new List<int>(trialResponseList);
            // remove any 3 entries from biaslist (no response trials)
            biasList.RemoveAll(x => x == 3);
            // if biasList is less than biasWindow, pad end with zeros
            while (biasList.Count < biasWindow) { biasList.Add(0); }
            // trim biasList to biasWindow length
            while (biasList.Count > biasWindow) { biasList.RemoveAt(biasList.Count - 1); }


            ///// Pick speed pair to test /////
            Tuple<double,double> speeds2show;
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
            int rightFaster = 1;
            float pRight = pRightManual;

            // if autobias is on, calculate pRight based on recent trial history, more recent trials weighted more heavily
            if (autoBias)
            {
                float biasSum = 0f;
                float totalNorm = 0f;
                for (int i = 0; i < biasList.Count; i++)
                {
                    float weight = (float)(biasList.Count - i) / (float)biasList.Count; // linearly decreasing weight
                    biasSum += biasList[i] * weight;
                    totalNorm += 1f * weight;

                    Console.WriteLine("BiasList " + biasList[i] + " Weight " + weight);
                }
                float bias = biasSum / totalNorm; // weighted average of recent trial results

                //scale bias by biasScaling parameter
                bias = bias * biasScaling;

                // bias can be from -1 to 1, where -1 is all left choices, 1 is all right choices
                // convert bias to pRight, where bias of 0 gives pRight of 0.5, 
                // bias of 1 gives pRight of 0 and bias of -1 gives pRight of 1
                pRight = 0.5f - (bias / 2f);

                // ensure pRight is between minPRight and 1-minPRight
                pRight = Math.Max(minPRight, Math.Min(1f - minPRight, pRight));

                // check bias list contains at least one -1 or 1, otherwise set pRight to manual
                if (!biasList.Any(x => x == 1) && !biasList.Any(x => x == -1))
                {
                    pRight = pRightManual;
                    Console.WriteLine("AutoBias ON but no bias data, using manual pRight: " + pRight);
                }
                else
                {
                    Console.WriteLine("Estimated bias: " + bias + " resulting in pRight: " + pRight);
                }
            }


            // now use random number to choose whether left or right is faster
            float biasrnd = (float)rng.NextDouble(); // random number for left / right faster

            // first check if maxInARow trials have just been shown (consecutively all left or all right)
            //if (rightInARow.All(x => x == 1)) {biasrnd = 1.1f;} // if list is all rights, next trial must be left
            //if (rightInARow.All(x => x == -1)) { biasrnd = -0.1f; } // if list is all lefts, next trial must be right

            // first check if maxInARow trials have just been shown (results consecutively all left or all right)
            if (maxInARowList.All(x => x == 1)) {biasrnd = 1.1f; Console.WriteLine("forced left trial");} // if list is all rights, next trial must be left
            if (maxInARowList.All(x => x == -1)){biasrnd = -0.1f; Console.WriteLine("forced right trial"); } // if list is all lefts, next trial must be right

            if (biasrnd <= pRight) // compare to pre-calculated pRight value (probability of right faster)
            {
                rightFaster = 1;
                speeds2show = new Tuple<double, double>(Speed1, Speed2);
            }
            else // if biasrnd>pRight
            {
                rightFaster = -1; // left is faster
                speeds2show = new Tuple<double, double>(Speed2, Speed1);
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
