# Structural Parcellation shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."

# $1: enquiry image
# $2: atlas folder "in_vivo" or "ex_vivo"
# $3: if exist, read user defined parameters
echo "***************************************************"
echo "* CAUTION!! DO NOT use the same name as the atlas *"
echo "*     if it is not for leave-one-out testing      *"
echo "***************************************************"
echo "usage: parcellation.sh new_image corresponding_mask atlas_folder"

# setup default value for parameters
ROOT_DIR=$(pwd)
PARCELLATION_NNR="-ln 4 -lp 4 -sx -3"
DILATE=3 # value to be dilated for the result mask
LABFUSION="-STEPS"
LABFUSION_OPTION="-v 1" # parameter options for STAPLE or STEPS in seg_LabFusion
MASK_AFF=""

# Set STEPS parameters
if [[ -z $k ]] && [[ -z $n ]]; then  # if STEPS parameter is not set
  # set default STEPS parameter to: "3 8 "
  export k=3
  export n=8
fi
export STEPS_PARAMETER="${k} ${n} "

FULL_TEST_NAME=$(basename $1)
TEST_NAME=`echo "$FULL_TEST_NAME" | cut -d'.' -f1`
echo "Creating parcellation label for: "$TEST_NAME
ATLAS=$(basename $2)

# Read user-defined parameters
if [ ! -z $3 ]; then # check if there is a 4th argument
  if [ -f $3 ]; then # check if the file specified by 4th argument exist
    . $3 # if file of 4th argument exist, read the parameters from the file
  fi
fi

if [ ! -d job_output ]; then mkdir job_output; fi
if [ ! -d job_error ]; then mkdir job_error; fi
if [ ! -d temp/${ATLAS} ]; then mkdir -p temp/${ATLAS}; fi
if [ ! -d mask/${ATLAS} ]; then mkdir -p mask/${ATLAS}; fi
if [ ! -d label/${ATLAS} ]; then mkdir -p label/${ATLAS}; fi

# echo "*********************************************"
# echo "* Segmentation pipeline for mouse brain MRI *"
# echo "* for ${TEST_NAME} *"
# echo "*  using multi-atlas label fusion methods   *"
# echo "*     step 2 - structural parcellation      *"
# echo "*********************************************"
# echo "usage: parcellation new_image mask atlas_type (in_vivo/ex_vivo)"

# start structural parcellation
echo "Creating label for: "$TEST_NAME
PARAMETER_NUMBER=0
jid="$$" # generate a random number as job ID
jid_reg="reg_${jid}"
TEST_NAME=`echo "$(basename $1)" | cut -d'.' -f1`
MASK=${MASK_FOLDER}/${TEST_NAME}${MASK_SUFFIX}
MERGE_LABEL=""
for G in `ls $2/template/`
do
  NAME=`echo "$G" | cut -d'.' -f1`
  # Check testing image name is different from atlas template. If same, skip (for leave-one-out)
  if [[ ${3}/template/${NAME} != $1 ]] && [[ ${3}/template/${NAME}.nii != $1 ]] && [[ ${3}/template/${NAME}.nii.gz != $1 ]] && [[ ${3}/template/${NAME}.hdr != $1 ]]
  then
	# prepare parameters for label fusion
    if (( $PARAMETER_NUMBER==0 )); then
      FIRST_TEMPLATE="temp/${ATLAS}/${NAME}_${TEST_NAME}_f3d.nii.gz"
 	  FIRST_MASK="mask/${ATLAS}/${TEST_NAME}_nrr_mask_${NAME}.nii.gz"
	  FIRST_LABEL="label/${ATLAS}/${TEST_NAME}_label_${NAME}.nii.gz"
    else
      MERGE_TEMPLATE="${MERGE_TEMPLATE} temp/${ATLAS}/${NAME}_${TEST_NAME}_f3d.nii.gz"
	  MERGE_MASK="${MERGE_MASK} mask/${ATLAS}/${TEST_NAME}_nrr_mask_${NAME}.nii.gz"
	  MERGE_LABEL="${MERGE_LABEL} label/${ATLAS}/${TEST_NAME}_label_${NAME}.nii.gz"
    fi
    let PARAMETER_NUMBER+=1
  else
	echo -e "Atlas image name ${TEST_NAME} is same as test image, skipped"
  fi
done
let PARAMETER_NUMBER-=1

# Prepare 4D images for label fusion
jid_4d="merge4d_${TEST_NAME}"

# create average rough mask to reduce memory usage for label fusion
if [ ! -f mask/${ATLAS}/${TEST_NAME}_nrr_mask_avg_bin.nii.gz ]; then
  reg_average mask/${ATLAS}/${TEST_NAME}_nrr_mask_avg.nii.gz -avg $FIRST_MASK $MERGE_MASK
  seg_maths mask/${ATLAS}/${TEST_NAME}_nrr_mask_avg.nii.gz -bin -dil ${DILATE} mask/${ATLAS}/${TEST_NAME}_nrr_mask_avg_bin.nii.gz
fi
  
MASK="mask/${ATLAS}/${TEST_NAME}_nrr_mask_avg_bin.nii.gz"

# merge 4D masks if not done yet
if [ ! -f mask/${ATLAS}/${TEST_NAME}_nrr_mask_4D.nii.gz ]; then
  seg_maths $FIRST_MASK -v -merge $PARAMETER_NUMBER 4 $MERGE_MASK mask/${ATLAS}/${TEST_NAME}_nrr_mask_4D.nii.gz
else
  echo "4D mask already exist, skip merging again"
fi
# merge 4D labels if not done yet
if [ ! -f label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz ]; then
  seg_maths $FIRST_LABEL -v -merge $PARAMETER_NUMBER 4 $MERGE_LABEL label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz
else
  echo "4D label already exist, skip merging again"
fi

# Start label fusion
export jid_LabFusion="LabFusion_${TEST_NAME}"
# Determine which label fusion method to use
if [ ${LABFUSION} == "-STEPS" ]; then
  # merge 4D template if not done yet
  if [ ! -f label/${ATLAS}/${TEST_NAME}_template_4D.nii.gz ]; then
    seg_maths $FIRST_TEMPLATE -v -merge $PARAMETER_NUMBER 4 $MERGE_TEMPLATE label/${ATLAS}/${TEST_NAME}_template_4D.nii.gz
  else
	echo "4D template already exist, skip merging again"
  fi
  # create final label using label fusion
  seg_LabFusion\
  -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz \
  -mask ${MASK}\
  -STEPS ${k} ${n} $1 label/${ATLAS}/${TEST_NAME}_template_4D.nii.gz ${LABFUSION_OPTION} \
  -out label/${TEST_NAME}_label_${ATLAS}_STEPS_${k}_${n}.nii.gz
#  jid_NRR_mask="NRR_mask_${TEST_NAME}"
#  ${QSUB_CMD} -hold_jid ${jid_4d}_* -N ${jid_NRR_mask} seg_LabFusion -in mask/${ATLAS}/${TEST_NAME}_nrr_mask_4D.nii.gz -mask ${MASK} -STEPS ${k} ${n} $1 label/${ATLAS}/${TEST_NAME}_template_4D.nii.gz ${LABFUSION_OPTION} -out mask/${TEST_NAME}_mask_${ATLAS}_NRR_STEPS_${k}_${n}.nii.gz
#  jid_NRR_mask_dilate="dil_NRR_mask_${TEST_NAME}"
#  ${QSUB_CMD} -hold_jid ${jid_NRR_mask} -N ${jid_NRR_mask_dilate} seg_maths mask/${TEST_NAME}_mask_${ATLAS}_NRR_STEPS_${k}_${n}.nii.gz -dil ${DILATE} mask/${TEST_NAME}_mask_${ATLAS}_NRR_STEPS_${k}_${n}_d${DILATE}.nii.gz
elif [ ${LABFUSION} == "-STAPLE" ]; then
  seg_LabFusion\
  -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz \
  -mask ${MASK}\
  -STAPLE ${LABFUSION_OPTION} \
  -out label/${TEST_NAME}_label_${ATLAS}_STAPLE.nii.gz
elif [ ${LABFUSION} == "-SBA" ]; then
  seg_LabFusion\
  -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz \
  -mask ${MASK}\
  -SBA ${LABFUSION_OPTION} \
  -out label/${TEST_NAME}_label_${ATLAS}_SBA.nii.gz
else # elif [[ ${LABFUSION }== "-MV" ]]; then
  seg_LabFusion\
  -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz \
  -mask ${MASK}\
  -MV ${LABFUSION_OPTION} \
  -out label/${TEST_NAME}_label_${ATLAS}_MV.nii.gz
fi








