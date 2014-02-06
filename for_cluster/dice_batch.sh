# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.08.29

# usage: ./dice_batch.sh $1 $2 $3 $4 $5
# $1: destination atlas folder to be tested (only use label subfolder)
# $2: source atlas folder containing multiple manual labels
# $3: folder containing the parcellated structures
# $4: STEPS parameter k (kernel size in terms of voxel number)
# $5: STEPS parameter n (number of top ranked local atlas to select for label fusion)
ROOT_DIR=$(pwd)
# echo "Bash version ${BASH_VERSION}..."
export QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=9.9G -l tmem=9.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
ATLAS=$(basename $2)
LABEL_NUMBER=40

if [ ! -d Dice_Score/temp ]
  then mkdir -p Dice_Score/temp
fi
# Set STEPS parameters
if [[ ! -z $5 ]] && [[ ! -z $4 ]]; then  # if STEPS parameter is set (-z: zero = not set), so ! -z = set
  export k=$4
  export n=$5
else # if [[ -z "${STEPS_PARAMETER}" ]] set default STEPS parameter to: "3 8 "
  export k=3
  export n=8
fi
export STEPS_PARAMETER="${k} ${n} " 

# begin dice score calculation
for H in `ls $1/template/`
do
  TEST_IMAGE=`echo "$H" | cut -d'.' -f1`
  echo "******************************************"
  echo "* Dice score OF ${TEST_IMAGE} step 1 (STEPS $k $n) *"
  # echo "******************************************"
  # Step 1: Calculating Dice score for each sample
  ATLAS_IMAGE=`echo "$G" | cut -d'.' -f1`
  # jid=$$
  # j_stats=stats_${jid}
  j_stats=${TEST_IMAGE}_${ATLAS}_label_STEPS_${k}_${n}
  ${QSUB_CMD} -N ${j_stats} seg_stats $1/label/$H -D "\"label/${TEST_IMAGE}_${ATLAS}_label_STEPS_${k}_${n}.nii.gz\"" "\"Dice_Score/temp/${TEST_IMAGE}_${ATLAS}_label_STEPS_${k}_${n}.csv\"" 
done