# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.08.29

# to test parameters used for MLSTEPS
# usage: ./STEPS_optimisation_dice.sh $1 $2
# $1: atlas (in_vivo ex_vivo)
# $2: sample number
# echo "Bash version ${BASH_VERSION}"
export QSUB_CMD="qsub -l h_rt=10:00:00 -l h_vmem=3.5G -l vf=3.5G -l s_stack=10240 -j y -S /bin/sh -b y -cwd -V"

# Load default value for parameter
KERNAL_MIN=1
KERNAL_MAX=9
SAMPLE_NUMBER=10 # total number of sample in the atlas
# Read user defined sample number
if [ ! -z $2 ]; then # check if there is a 3rd argument
  SAMPLE_NUMBER=$2 # assign userd-defined total number of sample in the atlas
fi

# TITLE_LINE=$(date +"%m-%d-%y")
for ((kX2=$KERNAL_MIN*2;kX2<=$KERNAL_MAX*2;kX2+=1)) #{1..6}
do
  for ((n=3;n<$SAMPLE_NUMBER;n+=1)) # or: for i in {1..20}
  do
    k=$(echo "scale=1;$kX2/2"|bc)
    . leave_one_out_dice.sh $1 $k $n # exporting dice score
  done
done

