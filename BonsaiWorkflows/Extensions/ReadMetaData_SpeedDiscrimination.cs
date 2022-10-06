using Bonsai;
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Reactive.Linq;

[Combinator]
[Description("")]
[WorkflowElementCategory(ElementCategory.Transform)]
public class ReadMetaData_SpeedDiscrimination
{

    public IObservable<Tuple<List<float>, List<float>, List<List<float>>, List<List<float>>, List<List<int[]>>>> Process(IObservable<IList<float[]>> source)
    {
        // input is a List<float[]> with list indexing rows of csv and float[] columns:
        // 1st: standard speeds (from 2nd column), 2nd: standard speed probs (from 2nd column), 
        // 3rd+ speed differences (1st column) with corresponding probs for standard speeeds (from 2nd column)

        return source.Select(value => 
        {
            // declare output variables
            List<float> StandardSpeedsList = new List<float>();
            List<float> StandardSpeedsProbList = new List<float>();
            List<List<float>> SpeedDifferencesList = new List<List<float>>();
            List<List<float>> SpeedDifferencesProbList = new List<List<float>>();
            List<List<int[]>> PerfTrackList = new List<List<int[]>>();

            // Standard Speeds List
            StandardSpeedsList.AddRange(value[0]);
            StandardSpeedsList.RemoveAt(0);
            int nSpeeds = StandardSpeedsList.Count();

            // Standard Speeds Probability List
            StandardSpeedsProbList.AddRange(value[1]);
            StandardSpeedsProbList.RemoveAt(0);

            // Speed Differences List
            int nSpeedDifferences = value.Count()-2; // first 2 rows have junk data due to structure of csv
            List<float> speedDiffs = new List<float>();
            for (int i=2; i<value.Count(); i++)
            {
                speedDiffs.Add(value[i][0]);
            }

            for (int ispeed=0; ispeed<nSpeeds; ispeed++) // in this case, the speed difference list is the same for each speed
            {
                SpeedDifferencesList.Add(speedDiffs);
            }


            // Speed Difference Probability List
            for (int ispeed=0; ispeed<nSpeeds; ispeed++)
            {
                List<float> tempList = new List<float>();
                for (int i=2; i<value.Count(); i++)
                {
                    tempList.Add(value[i][ispeed+1]);
                }

                SpeedDifferencesProbList.Add(tempList);
            }

            // Performance Tracking  List
            int[] intArr = {0, 0, 0, 0};
            
            List<int[]> tempPerfList = new List<int[]>();
            for (int i=0; i<nSpeedDifferences; i++) // create a list<int[]> with count = nSpeedDiffs
            {
                tempPerfList.Add(intArr);
            }

            for (int ispeed=0; ispeed<nSpeeds; ispeed++) // list of list<int[]>, for each standard speed
            {
                PerfTrackList.Add(tempPerfList);
            }


            // create output Tuple
            var output = Tuple.Create(StandardSpeedsList, StandardSpeedsProbList, SpeedDifferencesList, SpeedDifferencesProbList, PerfTrackList);
            
            return output;

            

        });
    }
}
