# Structural Parcellation shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.08.29 to be modified ...
#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."

# $1: enquiry image
# $2: atlas folder "in_vivo" or "ex_vivo"

if [ ! -d job_output ]
  then mkdir job_output
fi
if [ ! -d job_error ]
  then mkdir job_error
fi
if [ ! -d temp/${ATLAS} ]
  then mkdir -p temp/${ATLAS}
fi
if [ ! -d label/${ATLAS} ]
  then mkdir - label/${ATLAS}
fi

# setup default value for parameters
ROOT_DIR=$(pwd)
QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=9.9G -l tmem=9.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -l h_vmem=12G -l tmem=12G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
PARCELLATION_NNR="-ln 4 -lp 4 -sx 3 -sy 3 -sz 3"
DILATE=4 # value to be dilated for the result mask
LABFUSION="-STEPS"
MASK_AFF=" -rigOnly "

FULL_TEST_NAME=$(basename $1)
TEST_NAME=`echo "$FULL_TEST_NAME" | cut -d'.' -f1`
ATLAS=$(basename $2)

# start structural parcellation
echo "Creating 4D-label for: "$TEST_NAME
PARAMETER_NUMBER=0
for G in `ls $2/template/`
do
  jname=${jid_reg}_${G}
  NAME=`echo "$G" | cut -d'.' -f1`
  # Check testing image name is different from atlas template. If same, skip (for leave-one-out)
  if [[ ${3}/template/${NAME} != $1 ]] && [[ ${3}/template/${NAME}.nii != $1 ]] && [[ ${3}/template/${NAME}.nii.gz != $1 ]] && [[ ${3}/template/${NAME}.hdr != $1 ]]
  then
	# prepare parameters for label fusion
    if (( $PARAMETER_NUMBER==0 )); then
      FIRST_TEMPLATE="temp/${ATLAS}/${NAME}_${TEST_NAME}_f3d.nii.gz" 
	  FIRST_LABEL="label/${ATLAS}/${TEST_NAME}_label_${NAME}.nii.gz"
    else
      MERGE_TEMPLATE="${MERGE_TEMPLATE} temp/${ATLAS}/${NAME}_${TEST_NAME}_f3d.nii.gz" 
	  MERGE_LABEL="${MERGE_LABEL} label/${ATLAS}/${TEST_NAME}_label_${NAME}.nii.gz"
    fi
    let PARAMETER_NUMBER+=1
  else
	echo -e "Atlas image name ${TEST_NAME} is same as test image, skipped"
  fi
done
let PARAMETER_NUMBER-=1

# Prepare 4D images for label fusion
jid="$$" # generate random number as job ID
jid_4d="${jid}_4d"
jid_4d_label="label_${jid_4d}"
${QSUB_SEG_MATH} -N ${jid_4d_label} seg_maths $FIRST_LABEL -merge $PARAMETER_NUMBER 4 $MERGE_LABEL label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz
jid_4d_template="template_${jid_4d}"
${QSUB_SEG_MATH} -N ${jid_4d_template} seg_maths $FIRST_TEMPLATE -merge $PARAMETER_NUMBER 4 $MERGE_TEMPLATE label/${ATLAS}/${TEST_NAME}_template_4D.nii.gz
















