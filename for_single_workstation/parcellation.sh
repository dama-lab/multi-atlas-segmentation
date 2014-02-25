# Structural Parcellation shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)

# $1: enquiry image
# $2: mask for enquiry image.  if no mask just type "no_mask"
# $3: atlas folder "in_vivo" or "ex_vivo"
# $4: if exist, read user defined parameters

#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."
echo "***************************************************"
echo "* CAUTION!! DO NOT use the same name as the atlas *"
echo "*     if it is not for leave-one-out testing      *"
echo "***************************************************"
echo "usage: parcellation.sh new_image corresponding_mask atlas_folder"

# if [ ! -d job_output ]; then mkdir job_output; fi
# if [ ! -d job_error ]; then mkdir job_error; fi

# setup default value for parameters
ROOT_DIR=$(pwd)
export QSUB_CMD="qsub -l h_rt=5:00:00 -l h_vmem=4G -l tmem=4G -l s_stack=1024M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
export QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -l h_vmem=8G -l tmem=8G -l s_stack=1024M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
PARCELLATION_NNR="-ln 4 -lp 4"
DILATE=1 # value to be dilated for the result mask
LABFUSION="-STEPS"
MASK_AFF=" "

# Set STEPS parameters
if [[ -z $k ]] && [[ -z $n ]]; then  # if STEPS parameter is not set
  # set default STEPS parameter to: "3 8 "
  export k=3
  export n=8
fi
export STEPS_PARAMETER="${k} ${n} "

# Read user-defined parameters
if [ ! -z $4 ]; then # check if there is a 4th argument
  if [ -f $4 ]; then # check if the file specified by 4th argument exist
    . $4 # if file of 4th argument exist, read the parameters from the file
  fi
fi

FULL_TEST_NAME=$(basename $1)
TEST_NAME=`echo "$FULL_TEST_NAME" | cut -d'.' -f1`
echo "Creating parcellation label for: "$TEST_NAME
ATLAS=$(basename $3)
MASK=$2

if [ ! -d temp ]
  then mkdir temp
fi
if [ ! -d temp/${ATLAS} ]
  then mkdir temp/${ATLAS}
fi
# create dilated mask for every template image if not already exist
if [ ! -d $3/mask ]; then
  echo "create mask for every template image if not done yet"
  mkdir $3/mask
fi
if [ ! -d $3/mask_dilate ]; then
  echo "create dilated mask for every template image if not done yet"
  mkdir $3/mask_dilate
fi
if [ ! -d job_output ]
then mkdir job_output
fi
if [ ! -d job_error ]
then mkdir job_error
fi

for G in `ls $3/template/`
do
  if [ ! -f $3/mask_dilate/$G ] && [ ! -f $3/mask_dilate/$G".nii" ] && [ ! -f $3/mask_dilate/$G".nii.gz" ] && [ ! -f $3/mask_dilate/$G".hdr" ]; then
    if [ ! -f $3/mask/$G ] && [ ! -f $3/mask/$G".nii" ] && [ ! -f $3/mask/$G".nii.gz" ] && [ ! -f $3/mask/$G".hdr" ]; then
      reg_tools -in $3/label/$G -bin -out $3/mask/$G
    fi
    seg_maths $3/mask/$G -dil ${DILATE} $3/mask_dilate/$G
  fi
done

if [ ! -d label ]
  then mkdir label
fi
if [ ! -d label/${ATLAS} ]
  then mkdir label/${ATLAS}
fi

# "$$": generate a random number as job ID
# if no mask has been created yet, evoke mask.sh
if [ ! -f $2 ] && [ ! -f $2".nii" ] && [ ! -f $2".nii.gz" ] && [ ! -f $2".hdr" ]
then
  # create mask for the test image first
	if [ ! -z $4 ] && [ -f $4 ];  # check if there is a 4th argument# check if the file specified by 4th argument exist
	then . mask.sh $1 $3 $4 # if file of 4th argument exist, read the parameters from the file
	else . mask.sh $1 $3 # if there's no 4th argument or file not exist ("." eauqals to "source")
	fi # if path of the script is not defined in bashrc, use "./mask.sh" instead
  # Mask for the test image created
  MASK=mask/${TEST_NAME}_mask_${ATLAS}_STAPLE_d${DILATE}.nii.gz
  echo -e "Pre-defined mask ${MASK} NOT found, parcellation will start after the mask is generated"
else
  echo -e "Pre-defined mask ${MASK} found, start to search/generate initial affine registration from atlas to test image now"
fi

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
TEST_NAME=`echo "$(basename $1)" | cut -d'.' -f1`
for G in `ls $3/template/`
do
  NAME=`echo "$G" | cut -d'.' -f1`
  jname=${jid_reg}_${TEST_NAME}_${NAME}
  # Check testing image name is different from atlas template. If same, skip (for leave-one-out)
  if [[ ${3}/template/${NAME} != $1 ]] && [[ ${3}/template/${NAME}.nii != $1 ]] && [[ ${3}/template/${NAME}.nii.gz != $1 ]] && [[ ${3}/template/${NAME}.hdr != $1 ]]
  then
	# check if affine matrix exists as initialization for non-rigid registration. If no, generate it
	if [ ! -f temp/${ATLAS}/${TEST_NAME}_${NAME}_inv_aff ]; then
	  # generate affine test->atlas
	  reg_aladin -flo $1 -ref ${3}/template/${NAME} -rmask ${3}/mask_dilate/${NAME} -res temp/${ATLAS}/${TEST_NAME}_${NAME}_aff.nii.gz -aff temp/${ATLAS}/${TEST_NAME}_${NAME}_aff ${MASK_AFF}
	  # generate inv_affine atlas->test
	  reg_transform -ref ${3}/template/${NAME} -invAffine temp/${ATLAS}/${TEST_NAME}_${NAME}_aff temp/${ATLAS}/${TEST_NAME}_${NAME}_inv_aff 
	else
	  echo -e "Pre-defined affine transformation matrix ${TEST_NAME}_${NAME}_inv_aff found, begin non-rigid registration now"
	  
	fi
	# use affine transform matrix to initialize non-rigid registration
	reg_f3d -flo ${3}/template/${NAME} -fmask ${3}/mask_dilate/${NAME} -ref ${1} -rmask ${MASK} -aff temp/${ATLAS}/${TEST_NAME}_${NAME}_inv_aff -res temp/${ATLAS}/${NAME}_${TEST_NAME}_f3d.nii.gz -cpp temp/${ATLAS}/${NAME}_${TEST_NAME}_cpp.nii.gz ${PARCELLATION_NNR}
	# apply control point to generate transformed label from atlas to test image
    job_resample="${jname}_resample"
	reg_resample -flo ${3}/label/${NAME} -ref ${1} -cpp temp/${ATLAS}/${NAME}_${TEST_NAME}_cpp.nii.gz -NN -res label/${ATLAS}/${TEST_NAME}_label_${NAME}.nii.gz
    
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
seg_maths $FIRST_LABEL -merge $PARAMETER_NUMBER 4 $MERGE_LABEL label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz
# Start label fusion
# Determine which label fusion method to use
if [[ ${LABFUSION}=="-STEPS" ]]; then
  seg_maths $FIRST_TEMPLATE -merge $PARAMETER_NUMBER 4 $MERGE_TEMPLATE label/${ATLAS}/${TEST_NAME}_template_4D.nii.gz
  seg_LabFusion -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz -STEPS ${k} ${n} $1 label/${ATLAS}/${TEST_NAME}_template_4D.nii.gz -out "label/${TEST_NAME}_label_${ATLAS}_STEPS_${k}_${n}.nii.gz"
  # potential suffix: _NNG_${PARCELLATION_NNR} ?
  seg_maths label/${TEST_NAME}_label_${ATLAS}_STEPS_${k}_${n}.nii.gz -bin mask/${TEST_NAME}_mask_${ATLAS}_NRR_STEPS_${k}_${n}.nii.gz
  seg_maths mask/${TEST_NAME}_mask_${ATLAS}_NRR_STEPS_${k}_${n}.nii.gz -dil ${DILATE} mask/${TEST_NAME}_mask_${ATLAS}_NRR_STEPS_${k}_${n}_d${DILATE}.nii.gz
fi
















