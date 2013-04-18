# Structural Parcellation shell script (non-SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.5_2012.12.06

#!/bin/bash
# $1: enquiry image
# $2: mask for enquiry image.  if no mask just type "no_mask"
# $3: atlas folder "in_vivo" or "ex_vivo"
# $4: parameter file (if exist, otherwise, will use default parameter values)

QSUB_CODE="qsub -l h_rt=1:00:00 -l h_vmem=1.9G -l tmem=1.9G -l s_stack=10240 -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error "
PARCELLATION_NNR="-ln 4 -lp 4 -sx 3 -sy 3 -sz 3"
MASK_AFF=" -rigOnly "
# Read user-defined parameters
if [ ! -z $4 ]; then # check if there is a 4th argument
  if [ -f $4 ]; then # check if the file specified by 4th argument exist
    . $4 # if file of 4th argument exist, read the parameters from the file
  fi
fi

echo "***************************************************"
echo "* CAUTION!! DO NOT use the same name as the atlas *"
echo "*     if it is not for leave-one-out testing      *"
echo "***************************************************"

ROOT_DIR=$(pwd)
FULL_TEST_NAME=$(basename $1)
TEST_NAME=`echo "$FULL_TEST_NAME" | cut -d'.' -f1`
echo "Creating parcellation label for: "$TEST_NAME
MASK=$2
if [ -z $STEPS_PARAMETER ]; then # if STEPS parameter has not been defined (string=0, e.g. not called by fine_tune.sh)
  export STEPS_PARAMETER="4 6" # set up the optimized value for STEPS_PARAMETER
fi

# create dilated mask for every template image
if [ ! -d $3/mask ]
then
  echo "create mask for every template image if not done yet"
  mkdir $3/mask
fi
if [ ! -d $3/mask_dilate ]
then
  echo "create dilated mask for every template image if not done yet"
  mkdir $3/mask_dilate
fi
for G in `ls $3/template/`
do
  if [ ! -f $3/mask_dilate/$G ] && [ ! -f $3/mask_dilate/$G".nii" ] && [ ! -f $3/mask_dilate/$G".nii.gz" ] && [ ! -f $3/mask_dilate/$G".hdr" ]
  then
    if [ ! -f $3/mask/$G ] && [ ! -f $3/mask/$G".nii" ] && [ ! -f $3/mask/$G".nii.gz" ] && [ ! -f $3/mask/$G".hdr" ]
    then reg_tools -in $3/label/$G -bin -out $3/mask/$G
    fi
    seg_maths $3/mask/$G -dil 3 $3/mask_dilate/$G
  fi
done

if [ ! -d label ]
then mkdir label
fi
if [ ! -d label/temp ]
then mkdir label/temp
fi

if [ ! -f $2 ] && [ ! -f $2".nii" ] && [ ! -f $2".nii.gz" ] && [ ! -f $2".hdr" ]
then
  ./mask.sh $1 $3
  MASK=mask/$TEST_NAME"_mask_STAPLE_d.nii.gz"
fi

echo "*********************************************"
echo "* Segmentation pipeline for mouse brain MRI *"
echo "*  using multi-atlas label fusion methods   *"
echo "*     step 2 - structural parcellation      *"
echo "*********************************************"
echo "usage: parcellation new_image mask atlas_type (in_vivo/ex_vivo)"

# start structural parcellation
PARAMETER_NUMBER=0
for G in `ls $3/template/`
do
  NAME=`echo "$G" | cut -d'.' -f1`
  # Check testing image name is different from atlas template. If same, skip (for leave-one-out)
  if [[ $3/template/$NAME != $1 ]] && [[ $3/template/$NAME.nii != $1 ]] && [[ $3/template/$NAME.nii.gz != $1 ]] && [[ $3/template/$NAME.hdr != $1 ]]
  then
	# check whether affine deformation already performed
	if [ ! -f temp/$TEST_NAME"_"$NAME"_inv_aff" ]
	  then
	  # deform without affine initialisation will lead to pool result, so generate one first (same as in mask.sh)
	  reg_aladin -flo $1 -ref $3/template/${NAME} -rmask $3/mask_dilate/${NAME} -aff temp/${TEST_NAME}_${NAME}_aff -res temp/${TEST_NAME}_${NAME}_aff.nii.gz ${MASK_AFF}
	  reg_transform -ref $3/template/$G -invAffine temp/${TEST_NAME}_${NAME}_aff temp/${TEST_NAME}_${NAME}_inv_aff
	fi
	NNR="reg_f3d -flo ${3}/template/${NAME} -ref $1 -rmask $MASK -aff temp/${TEST_NAME}_${NAME}_inv_aff -res label/temp/${NAME}_${TEST_NAME}_f3d.nii.gz -cpp label/temp/${NAME}_${TEST_NAME}_cpp.nii.gz $PARCELLATION_NNR"
	  $NNR
    reg_resample -flo $3/label/$NAME -ref $1 -cpp label/temp/$NAME"_"$TEST_NAME"_cpp.nii.gz" -NN -res label/temp/$TEST_NAME"_label_"$NAME".nii.gz"
   
    if (( $PARAMETER_NUMBER==0 ))
      then
        FIRST_TEMPLATE=label/temp/$NAME"_"$TEST_NAME"_f3d.nii.gz" 
	    FIRST_LABEL=label/temp/$TEST_NAME"_label_"$NAME".nii.gz"
    else
      MERGE_TEMPLATE=$MERGE_TEMPLATE" "label/temp/$NAME"_"$TEST_NAME"_f3d.nii.gz" 
	  MERGE_LABEL=$MERGE_LABEL" "label/temp/$TEST_NAME"_label_"$NAME".nii.gz"
    fi
    let PARAMETER_NUMBER+=1
  fi
done
let PARAMETER_NUMBER-=1

# start label fusion
seg_maths $FIRST_TEMPLATE -merge $PARAMETER_NUMBER 4 $MERGE_TEMPLATE label/temp/$TEST_NAME"_template_4D.nii.gz"
seg_maths $FIRST_LABEL -merge $PARAMETER_NUMBER 4 $MERGE_LABEL label/temp/$TEST_NAME"_label_4D.nii.gz"
# seg_LabFusion -in label/temp/$TEST_NAME"_label_4D.nii.gz" -STEPS 5 8 $1 label/temp/$TEST_NAME"_template_4D.nii.gz" -out label/$TEST_NAME"_label_STEPS.nii.gz"
seg_LabFusion -in label/temp/$TEST_NAME"_label_4D.nii.gz" -STEPS $STEPS_PARAMETER $1 label/temp/$TEST_NAME"_template_4D.nii.gz" -out label/$TEST_NAME"_label_STEPS_$STEPS_PARAMETER.nii.gz"
















