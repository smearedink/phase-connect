#!/bin/sh


##### (1) Entries that must be updated each time this script is run

# labels, going A, B, C...
# (if you are so unfortunate as to reach Z, just use AA, BB, CC, etc.)

# example for one step:

# prev_labels="A B C D"
# next_label="E"

prev_labels="A B"
next_label="C"

##### (2) Entries that can optionally be updated each time this script is run

# inner loops continue as long as chi2 is below this value
chi2_threshold="2.0"

##### (3) Entries that only need to be set at the beginning

# specify version of TEMPO we're using
# path to $TEMPO directory, which contains tempo.cfg, obsys.dat, etc.
TEMPO=
# path to tempo executable
alias tempo=

# specify where we are--this is the directory where we want to write our results
basedir=

# specify where we want to run this (RAM disk, like '/dev/shm/timing/')
rundir=

# specify the files we are going to work with
# (.par and .tim file names--these files should be in your basedir)
ephem=.par
timfile=.tim

##### YOU SHOULD NOT NEED TO EDIT BEYOND THIS LINE




# copy them and file with acceptable phase wraps to rundir

cp $ephem $timfile  acc_WRAPs.dat $rundir

# remove previous WRAPs file

rm -rf WRAPs.dat minima.dat

# go to rundir there and start calculation

cd $rundir

start=`date`

# How many acceptable solutions we have from previous wrapper output

n=`wc acc_WRAPs.dat | awk '{print $1}'`
n=`expr $n + 1`

# set the counter that will go through these solutions
m=1 

# Arbitrary positions we're sampling

z1=-20
z2=20

# set total counter
l=0

while [ "$m" -lt "$n" ]  # this is the outer loop, where we cycle through the acceptable solutions
do
   # ********** CHECK variable names and positions
   acc_combination=""
   edtim1_str="cat "$timfile" | "

   col=1
   for label in $prev_labels
   do
      this_label=`head -$m acc_WRAPs.dat | tail -1 | awk -v cvar="$col" '{print $cvar}'`
      acc_combination="$acc_combination"$this_label" "
      edtim1_str="$edtim1_str""sed 's/PHASE"$label"/PHASE "$this_label"/' | "
      col=`expr $col + 1`
   done

   edtim1_str="$edtim1_str""sed 's/PHASE"$next_label"/PHASE"

   chi2_prev=`head -$m acc_WRAPs.dat | tail -1 | awk -v cvar="$col" '{print $cvar}'`

   # ********** CHECK variable names and positions, and that the TOA list is accurate
   echo $edtim1_str > edtim1


   # Instead of spending most of the time doing stupid calculations with ridiculously large reduced
   # chi2's, we're going to calculate it in three random points and then deduce where the minimum is
   
   # Do the script for PHASE 0

         # Make a script for replacing the PHASE flags and run it
         echo "0/' > trial.tim " > edtim2 ; paste edtim1 edtim2 -d " " > edtim ; sh edtim
         # Run tempo on this file
         tempo trial.tim -f $ephem -w 
         chi2_0=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	 
	 
   # Do the script for PHASE z1

         # Make a script for replacing the PHASE flags and run it
         echo $z1"/' > trial.tim " > edtim2 ; paste edtim1 edtim2 -d " " > edtim ; sh edtim
         # Run tempo on this file
         tempo trial.tim -f $ephem -w 
         chi2_1=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	 
	 
   # Do the script for PHASE z2

         # Make a script for replacing the PHASE flags and run it
         echo $z2"/' > trial.tim " > edtim2 ; paste edtim1 edtim2 -d " " > edtim ; sh edtim
         # Run tempo on this file
         tempo trial.tim -f $ephem -w 
         chi2_2=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	
   # determine position of minimum (this should be reasonably accurate)

         min=`echo 'scale=0 ; ( '$z2'^2 *('$chi2_0' - '$chi2_1') + '$z1'^2*(-'$chi2_0' + '$chi2_2')) / (2.*('$z2'*('$chi2_0' - '$chi2_1') + '$z1'*(-'$chi2_0' + '$chi2_2'))) / 1.0 ' | bc -l`
    
   # Do the script for the best (minimum) phase

         # Make a script for replacing the PHASE flags and run it
         echo $min"/' > trial.tim " > edtim2 ; paste edtim1 edtim2 -d " " > edtim ; sh edtim
         # Run tempo on this file
         tempo trial.tim -f $ephem -w 
         chi2=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
	 echo $acc_combination $min $chi2 $chi2_prev >> WRAPs.dat 
	 
	 l=`expr $l + 1`
	 
   # write this in the file	 
   echo $chi2_0 $chi2_1 $chi2_2 $min $chi2 >> minima.dat
	  
   # **************** Do cycle going up in phase count
  
   z=`expr $min + 1`
   chi=1
   while [ "$chi" -eq 1 ]
   do	 
   
         # Make a script for replacing the PHASE flags and run it
         echo $z"/' > trial.tim " > edtim2 ; paste edtim1 edtim2 -d " " > edtim ; sh edtim
         # Run tempo on this file
         tempo trial.tim -f $ephem -w 
         chi2=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
         chi=`echo $chi2' < '$chi2_threshold | bc -l` 
	  
         echo $acc_combination $z $chi2 $chi2_prev >> WRAPs.dat 

         l=`expr $l + 1`
         z=`expr $z + 1`
   done
   
   
   # **************** Do cycle going down in phase count
  
   z=`expr $min - 1`
   chi=1   
   while [ "$chi" -eq 1 ]
   do	 
   
         # Make a script for replacing the PHASE flags and run it
         echo $z"/' > trial.tim " > edtim2 ; paste edtim1 edtim2 -d " " > edtim ; sh edtim
         # Run tempo on this file
         tempo trial.tim -f $ephem -w 
         chi2=`cat tempo.lis | tail -1 | awk -F= '{print $2}' | awk '{print $1}'`
         chi=`echo $chi2' < '$chi2_threshold | bc -l`
	 	 
         echo $acc_combination $z $chi2 $chi2_prev >> WRAPs.dat 

         l=`expr $l + 1`
         z=`expr $z - 1`
   done
 
   m=`expr $m + 1`
   echo "Done $m of $n loops." > progress.dat
done

# write results to disk

mv minima.dat WRAPs.dat $basedir

end=`date`

echo Made a total of $l trials
echo Started $start
echo Ended $end

cd $basedir

exit

