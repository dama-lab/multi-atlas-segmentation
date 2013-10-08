# Structural Parcellation shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.09.11
#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."

# $1: enquiry image
# $2: atlas folder "in_vivo" or "ex_vivo"
# $3: if exist, read user defined parameters

# echo "***************************************************"
# echo "* CAUTION!! DO NOT use the same name as the atlas *"
# echo "*     if it is not for leave-one-out testing      *"
# echo "***************************************************"
# echo "usage: labfusion_STAPLE.sh test_image atlas_folder"

# setup default value for parameters
ROOT_DIR=$(pwd)
QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=1.5G -l vf=1.5G -l s_stack=10240 -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -l h_vmem=10G -l vf=10G -l s_stack=256M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
DILATE=3 # value to be dilated for the result mask
LABFUSION="-STAPLE" # can be added to the user specified parameters 
if [ -z $STEPS_PARAMETER ]; then # if STEPS parameter has not been defined (string=0, e.g. not called by fine_tune.sh)
  export STEPS_PARAMETER="4 6" # set up the optimized value for STEPS_PARAMETER
fi
# Read user-defined parameters
if [ ! -z $3 ]; then # check if there is a 3th argument
  if [ -f $3 ]; then # check if the file specified by 3th argument exist
    . $3 # if file of 4th argument exist, read the parameters from the file
  fi
fi

FULL_TEST_NAME=$(basename $1)
TEST_NAME=`echo "$FULL_TEST_NAME" | cut -d'.' -f1`
echo "Creating parcellation label for: "$TEST_NAME
ATLAS=$(basename $2)

# create dilated mask for every template image if not already exist
if [ ! -d job_output ]
then mkdir job_output
fi
if [ ! -d job_error ]
then mkdir job_error
fi

jid=STAPLE_"$$" # generate a random number as job ID

# Start label fusion
export jid_LabFusion="${jid}_LabFusion"
# Determine which label fusion method to use
if [[ ${LABFUSION}=="-STAPLE" ]]; then
  ${QSUB_SEG_MATH} -N ${jid_LabFusion} seg_LabFusion -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz -STAPLE -out "\"label/${TEST_NAME}_${ATLAS}_label_STAPLE.nii.gz\""
fi
















