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
public class TrialManager_SpeedDiscrimination
{
    // This script manages trial-by-trial stimulus paramters (e.g. left and right stimulus speeds). 
    // It is triggered by a unit input and then uses it's properties to calculate the speeds
    // to use in the next trial (Tuple<double, double>). 
    // It also outputs some indexing variables related to the next trial.


    // Externalised properties
    public List<float> StandardSpeedsList {get; set; }
    public List<float> StandardSpeedsProbList {get; set; }
    public List<List<float>> SpeedDifferenceList {get; set; }  
    public List<List<float>> SpeedDifferenceProbList {get; set; }  
    public List<List<int[]>> PerfTrackList {get; set; } 
    public int itrial {get; set; }

    // left/right properties
    public List<int> rightInARow {get; set; } //
    public int maxInARow {get; set; }
    public bool autoBias {get; set; }
    public float biasScaling {get; set; }
    public float pRightManual {get; set; }
    public float minPRight {get; set; }
    
    
    public IObservable<Tuple<Tuple<double, double>,Tuple<int, int, int, int>>> Process(IObservable<Unit> source)
    {
        return source.Select(value => 
        {

        ////////// INTIALISE VARIABLES //////////

            var rng = new Random((int)DateTime.Now.Ticks); // random number generator
            float bias = 0f;
            float totalNorm = 0f;
            float pRight;
            int speedDifferenceIndex = 99;
            float speedDiff = 99f;
            int nSpeeds = StandardSpeedsList.Count();
            int standardSpeedIndex = 99;
            int nSpeedDiffs = 99;
            float standardSpeed = 0f;
            float jndSpeed = 0f;
            int rightFaster = 1;
            Tuple<double,double> speeds;

            if (itrial==1)
            {
                rightInARow = new List<int>();
                // rightInARow
            }
            //Console.WriteLine(itrial);
            

            //////////// PICK STANDARD SPEED TO TEST //////////
            int randomStandardSpeed = rng.Next(101); // random number between 1 and 100
            for (int i=0; i<nSpeeds; i++) // loop through standard speeds 
            {
                float sum = StandardSpeedsProbList.Take(i+1).Sum(); // take cumulative sum of standardSpeed probs up to this one
                if (randomStandardSpeed <= sum) // if the sum is more than the random number, choose it
                {
                    standardSpeedIndex = i; // index of the stajdard speed to be tested
                    nSpeedDiffs = SpeedDifferenceList[standardSpeedIndex].Count(); // number of possible speed ratios for this speed
                    standardSpeed = StandardSpeedsList[standardSpeedIndex];
                    break;
                }
            }


            ////////// PICK A SPEED DIFFERENCE TO TEST //////////
            int randomSpeedDiff = rng.Next(101); // random number between 1 and 100
            for (int i=0; i<nSpeedDiffs; i++) // loop through ratios until one is picked
            {
                float sum = SpeedDifferenceProbList[standardSpeedIndex].Take(i+1).Sum(); // take cumulative sum of speed difference probs up to this one
                if (randomSpeedDiff <= sum) // if the sum is more than the random number, choose it
                {
                    speedDifferenceIndex = i; 
                    speedDiff = SpeedDifferenceList[standardSpeedIndex][speedDifferenceIndex];
                    break;
                }
            }
            //jndSpeed = standardSpeed + (speedDiff * standardSpeed); 
            jndSpeed = standardSpeed * speedDiff;


            ////////// PICK WHETHER LEFT OR RIGHT SPEED IS FASTER /////////
            pRight = pRightManual; // assign manual by default, override if using autobias
            if (autoBias) // optional bias correction

            // calculate bias for this standard speed by looping through difference speed difference results
            { 
                for (int ispeed=0; ispeed<nSpeeds; ispeed++) // loop through standard speeds 
                {
                    nSpeedDiffs = SpeedDifferenceList[ispeed].Count(); 
                    for (int ispeedDiff=0; ispeedDiff<nSpeedDiffs; ispeedDiff++)
                    {   // here 1st [] indexes into perf track list for the mean speed, [speedDifferenceIndex] is speed diff index, [0:3] are the int array indexes
                    float nr = PerfTrackList[ispeed][ispeedDiff][0] + 1; // # right trials
                    float cr = PerfTrackList[ispeed][ispeedDiff][1] + 1; // # correct right trials
                    float nl = PerfTrackList[ispeed][ispeedDiff][2] + 1; // # left trials
                    float cl = PerfTrackList[ispeed][ispeedDiff][3] + 1; // # correct left trials
                    
                    // this speed difference contribution to bias is diff in proportion correct, weighted by speed difference, weighted by total trials for this difference.
                    // p(inc|right) - p(inc|left) --{L bias if high, R bias if low}
                    bias = bias + (((float)(1-cr/nr) - (float)(1-cl/nl)) * SpeedDifferenceList[ispeed][ispeedDiff] * (nl+nr));
                    totalNorm = totalNorm + (nl+nr)*SpeedDifferenceList[ispeed][ispeedDiff]; // normalisation factor depends on how big speed difference is.
                    }
                }
                Console.WriteLine("orig bias " + bias + " orig norm" + totalNorm );
                bias = bias / totalNorm; // bias is normalised to be between -1 and 1
                Console.WriteLine("norm bias " + bias);
                bias = bias / 2f; // rescale to between -.5 and .5
                Console.WriteLine(".5scale bias  = " + bias);
                pRight = 0.5f + (bias*biasScaling); // alter p(right) using calculated bias
                
                // ensure pRight doesn't go outside acceptable range
                if (pRight < minPRight) { pRight = minPRight; }
                if (pRight > 1-minPRight) { pRight = 1-minPRight;}
                Console.WriteLine("pright" + pRight);
                
            } //  end autobias

            // if first trials/error, revert to manual setting
            if (Single.IsNaN(pRight)) {pRight = pRightManual;}
            
            // now use random number to choose whether left or right is faster
            float biasrnd = (float)rng.NextDouble(); // random number for left / right faster

            // first check if maxInARow trials have just been shown (consecutively all left or all right)
            if (rightInARow.All(x => x == 1)) {biasrnd = 1;} // if list is all rights, next trial must be left
            if (rightInARow.All(x => x == -1)){biasrnd = 0;} // if list is all lefts, next trial must be right
            
            if (biasrnd <= pRight) // compare to pre-calculated pRight value (probability of right faster)
            {
            rightFaster = 1; // right is faster
            if (jndSpeed > standardSpeed) {speeds = new Tuple<double,double>(standardSpeed, jndSpeed);}
            else {speeds = new Tuple<double,double>(jndSpeed, standardSpeed);}
            }
            else // if biasrnd>pRight
            {
            rightFaster = -1; // left is faster
            if (jndSpeed > standardSpeed) {speeds = new Tuple<double,double>(jndSpeed, standardSpeed);}
            else {speeds = new Tuple<double,double>(standardSpeed, jndSpeed);}
            }

            // add right faster, remove first element from list if needed
            rightInARow.Add(rightFaster);
            while (rightInARow.Count > maxInARow) { rightInARow.RemoveAt(0); }


            //Console.WriteLine("StandardSpeed=" + standardSpeed + ", SpeedDiff=" + speedDiff + ", rightFaster?" + rightFaster);
            

            ///////////////////// GENERATE OUTPUTS ////////////////
            var otherInfo = new Tuple<int, int, int, int>(standardSpeedIndex, speedDifferenceIndex, rightFaster, nSpeedDiffs);
            var output = Tuple.Create(speeds, otherInfo);

            return output;
    });
    }
}
