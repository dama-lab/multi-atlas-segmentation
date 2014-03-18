# Structural Parcellation shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.09.11
#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."

# $1: enquiry image
# $2: atlas folder "in_vivo" or "ex_vivo"
# $3: STEPS parameter k (kernel size in terms of voxel number)
# $4: STEPS parameter n (number of top ranked local atlas to select for label fusion)
# $5: file that contains other LabFusion parameters

# echo "***************************************************"
# echo "* CAUTION!! DO NOT use the same name as the atlas *"
# echo "*     if it is not for leave-one-out testing      *"
# echo "***************************************************"
# echo "usage: labfusion_STAPLE.sh test_image atlas_folder"

# setup default value for parameters
ROOT_DIR=$(pwd)
QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=1.5G -l vf=1.5G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -l h_vmem=8G -l vf=8G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
DILATE=3 # value to be dilated for the result mask

# Set STEPS parameters
if [[ ! -z $3 ]] && [[ ! -z $4 ]]; then  # if STEPS parameter is set (-z: zero = not set), so ! -z = set
  export k=$3
  export n=$4
else # if [[ -z "${STEPS_PARAMETER}" ]] set default STEPS parameter to: "4 6"
  export k=5
  export n=8
fi
export STEPS_PARAMETER="${k} ${n} $5"

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
${QSUB_SEG_MATH} -N ${jid_LabFusion} seg_LabFusion -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz -STEPS -out "\"label/${TEST_NAME}_${ATLAS}_label_STAPLE.nii.gz\""
















