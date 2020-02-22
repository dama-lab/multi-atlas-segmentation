# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.08.29
# usage: ./leave_one_out_parcellation.sh $1 $2 $3
# $1: atlas (in_vivo ex_vivo)
# $2: STEPS parameter k (kernel size in terms of voxel number)
# $3: STEPS parameter n (number of top ranked local atlas to select for label fusion)
ROOT_DIR=$(pwd)
# echo "Bash version ${BASH_VERSION}..."
ATLAS=$(basename $1)
export QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=1.5G -l vf=1.5G -l s_stack=10240 -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

# Set STEPS parameters
if [[ ! -z $2 ]] && [[ ! -z $3 ]]; then  # if STEPS parameter is set (-z: zero = not set), so ! -z = set
  export k=$2
  export n=$3
else # if [[ -z "${STEPS_PARAMETER}" ]] set default STEPS parameter to: "4 6 "
  export k=4
  export n=6
fi
export STEPS_PARAMETER="${k} ${n} "

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

# create dilated mask for every template image
if [ ! -d $1/mask ]
then
  echo "create mask for every template image if not done yet"
  mkdir $1/mask
fi
if [ ! -d $1/mask_dilate ]
then
  echo "create dilated mask for every template image if not done yet"
  mkdir $1/mask_dilate
fi
for G in `ls $1/template/`
do
  if [ ! -f $1/mask_dilate/$G ] && [ ! -f $1/mask_dilate/$G".nii" ] && [ ! -f $1/mask_dilate/$G".nii.gz" ] && [ ! -f $1/mask_dilate/$G".hdr" ]
  then
    if [ ! -f $1/mask/$G ] && [ ! -f $1/mask/$G".nii" ] && [ ! -f $1/mask/$G".nii.gz" ] && [ ! -f $1/mask/$G".hdr" ]
    then reg_tools -in $1/label/$G -bin -out $1/mask/$G
    fi
    seg_maths $1/mask/$G -dil 3 $1/mask_dilate/$G
  fi
done

# begin parcellation and dice score calculation
for H in `ls $1/template/`
do
  TEST_NAME=`echo "$H" | cut -d'.' -f1`
  . parcellation.sh $1/template/$H $1/mask_dilate/$H $1
  echo "***************************************"
  echo "* Segmentation performance evaluation *"
  echo "*   step 3 - leave one out (STEPS)    *"
  echo "***************************************"
  # Calculate Dice Score for template image now put to a different script: "leave_one_out_dice.sh"
  jid=leave_one_out_"$$"
  ${QSUB_CMD} -hold_jid ${jid_LabFusion} -N ${jid} seg_stats $1/label/$H -D "\"label/${TEST_NAME}_${ATLAS}_label_STEPS_${k}_${n}.nii.gz\"" "\"$1/Dice_Score/temp/${TEST_NAME}_${ATLAS}_label_STEPS_${k}_${n}.csv\""
done
  