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

    // left/right properties
    public List<int> rightInARow {get; set; }
    public int maxInARow {get; set; }
    public bool autoBias {get; set; }
    public float biasScaling {get; set; }
    public float pRightManual {get; set; }
    public float minPRight {get; set; }
    
    
    public IObservable<Tuple<double, double>> Process(IObservable<Unit> source)
    {
        return source.Select(value => 
        {

        ////////// INTIALISE VARIABLES //////////

            Random rng = new Random((int)DateTime.Now.Ticks); // random number generator
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

            jndSpeed = standardSpeed + (speedDiff * standardSpeed);

            

            ////////// PICK WHETHER LEFT OR RIGHT SPEED IS FASTER /////////

            pRight = pRightManual; // assign manual by default, override if using autobias
            
            if (autoBias) // optional bias correction
            {

                // calculate bias for this standard speed by looping through difference speed difference results
            for (int i=0; i<nSpeedDiffs; i++)
            {   // here 1st [] indexes into perf track list for the mean speed, [speedDifferenceIndex] is speed diff index, [0:3] are the int array indexes
                float nr = PerfTrackList[standardSpeedIndex][speedDifferenceIndex][0] + 1; // # right trials
                float cr = PerfTrackList[standardSpeedIndex][speedDifferenceIndex][1] + 1; // # correct right trials
                float nl = PerfTrackList[standardSpeedIndex][speedDifferenceIndex][2] + 1; // # left trials
                float cl = PerfTrackList[standardSpeedIndex][speedDifferenceIndex][3] + 1; // # correct left trials

                // this speed difference contribution to bias is diff in proportion correct, weighted by speed difference, weighted by total trials for this difference.
                bias = bias + (((float)(cr/nr) - (float)(cl/nl)) * SpeedDifferenceList[standardSpeedIndex][speedDifferenceIndex] * (nl+nr));
                totalNorm = totalNorm + (nl+nr)*SpeedDifferenceList[standardSpeedIndex][speedDifferenceIndex]; // normalisation factor
            }
            bias = bias / totalNorm; // bias is normalised to be between 0 and 1
            pRight = 0.5f - (bias*biasScaling); // alter p(right) using calculated bias
            // ensure pRight doesn't go outside acceptable range
            if (pRight < minPRight) { pRight = minPRight; }
            if (pRight > 1-minPRight) { pRight = 1-minPRight;}
            } //  end autobias
            if (Single.IsNaN(pRight)) // if first trials/error, revert to manual setting
            {
                pRight = pRightManual;
            }
            
            // now use random number to choose whether left or right is faster
            float biasrnd = (float)rng.NextDouble(); // random number for left / right faster
            // check if too many fastest on left or right side in a row
            if (rightInARow.All(x => x == 1)) // if list is all right
            {
                biasrnd = 1; // next trial must be left
            }
            if (rightInARow.All(x => x == -1))
            {
                biasrnd = 0; // next trial must be right
            }
            
            if (biasrnd <= pRight) // compare to pre-calculated pRight value (probability of right faster)
            {
            rightFaster = 1; // right is faster
            if (jndSpeed > standardSpeed) {speeds = new Tuple<double,double>(standardSpeed, jndSpeed);}
            else {speeds = new Tuple<double,double>(jndSpeed, standardSpeed);}
            }
            else
            {
            rightFaster = -1; // left is faster
            if (jndSpeed > standardSpeed) {speeds = new Tuple<double,double>(jndSpeed, standardSpeed);}
            else {speeds = new Tuple<double,double>(standardSpeed, jndSpeed);}
            }

            // add right faster, remove first element from list if needed
            rightInARow.Add(rightFaster);
            if (rightInARow.Count > maxInARow)
            { 
                rightInARow.RemoveAt(0); 
            }

            return speeds;
    });
    }
}
