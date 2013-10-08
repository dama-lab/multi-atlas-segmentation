# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.09.12

# usage: ./leave_one_out_STAPLE.sh atlas (in_vivo ex_vivo)
# $1: atlas (in_vivo ex_vivo)
ROOT_DIR=$(pwd)
echo "Bash version ${BASH_VERSION}..."
ATLAS=$(basename $1)
export QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=9.9G -l tmem=9.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

# export STEPS_PARAMETER="4 6"

# if [ -f "$1/Dice_Score/Dice_Score_STEPS.csv" ]
# then
#  rm "$1/Dice_Score/Dice_Score_STEPS.csv"
# fi
if [ ! -d $1"/Dice_Score" ]
then mkdir $1"/Dice_Score"
fi
if [ ! -d $1"/Dice_Score/temp" ]
then mkdir $1"/Dice_Score/temp"
fi

jid=$$
# begin STAPLE label fusion and dice score calculation
for H in `ls $1/template/`
do
  # labfusion_STAPLE.sh $1/template/$H $1
  TEST_NAME=`echo "$H" | cut -d'.' -f1`
  echo "***********************************************************************"
  echo "* Segmentation performance evaluation step 3 - leave one out (STAPLE) *"
  echo "***********************************************************************"
  # Calculate Dice Score for template image
  j_staple=STAPLE_${jid}
  ${QSUB_CMD} -N ${j_staple} seg_LabFusion -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz -STAPLE -out "\"label/${TEST_NAME}_${ATLAS}_label_STAPLE.nii.gz\""
  jstat=stat_${jid}
  ${QSUB_CMD} -hold_jid ${j_staple} -N ${jstat} seg_stats $1/label/$H -D "\"label/${TEST_NAME}_${ATLAS}_label_STAPLE.nii.gz\"" "\"$1/Dice_Score/temp/${TEST_NAME}_${ATLAS}_label_STAPLE.csv\""
done
  