# Brain Extraction shell script (non-SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.6_2012.12.10 (add non-rigid for accurate brain extraction)
#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."

export QSUB_CODE="qsub -l h_rt=1:00:00 -l h_vmem=1.9G -l tmem=1.9G -l s_stack=10240 -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error "
#!/bin/bash

echo "*********************************************"
echo "* Segmentation pipeline for mouse brain MRI *"
echo "*  using multi-atlas label fusion methods   *"
echo "*         step 1 - brain extraction         *"
echo "*********************************************"
echo "usage: mask new_image atlas_type (in_vivo/ex_vivo)"
# $1: enquiry image
# $2: atlas folder "in_vivo" or "ex_vivo"
# Add $3: value to be dilated
# start brain extraction
ROOT_DIR=$(pwd)

if [ ! -f $1 ] && [ ! -f $1".nii" ] && [ ! -f $1".nii.gz" ] && [ ! -f $1".hdr" ]
then echo "test image not exist"
fi
if [ ! -d temp ]
then mkdir temp
fi
if [ ! -d mask ]
then mkdir mask
fi
if [ ! -d mask/temp ]
then mkdir mask/temp
fi
if [ ! -d $2/mask ]
then mkdir $2/mask
fi
if [ ! -d $2/mask_dilate ]
then mkdir $2/mask_dilate
fi

MASK_AFF=" -rigOnly "

# Mask back propagation
FULL_TEST_NAME=$(basename $1)
TEST_NAME=`echo "$FULL_TEST_NAME" | cut -d'.' -f1`
echo "Creating mask for: "$TEST_NAME
PARAMETER_NUMBER=0
for G in `ls $2/template/`
do
   NAME=`echo "$G" | cut -d'.' -f1`
   if [[ $2/template/$NAME != $1 ]] && [[ $2/template/$NAME.nii != $1 ]] && [[ $2/template/$NAME.nii.gz != $1 ]] && [[ $2/template/$NAME.hdr != $1 ]]
	   then
	   if [ ! -f $2/mask/$G ] && [ ! -f $2/mask/$G".nii" ] && [ ! -f $2/mask/$G".nii.gz" ] && [ ! -f $2/mask/$G".hdr" ]
		 then reg_tools -in $2/label/$G -bin -out $2/mask/$G
	   fi
	   if [ ! -f $2/mask_dilate/$G ]
		 then seg_maths $2/mask/$G -dil 3 $2/mask_dilate/$G
	   fi
	   reg_aladin -flo $1 -ref $2/template/$G -rmask $2/mask_dilate/$G -aff temp/$TEST_NAME"_"$NAME"_aff" -res temp/$TEST_NAME"_"$NAME"_aff".nii.gz ${MASK_AFF}
	   reg_transform -ref $2/template/$G -invAffine temp/$TEST_NAME"_"$NAME"_aff" temp/$TEST_NAME"_"$NAME"_inv_aff"
	   reg_resample -flo $2/mask/$G -ref $1 -aff temp/$TEST_NAME"_"$NAME"_inv_aff" -NN -res mask/temp/$TEST_NAME"_mask_"$G
	   
	   # change non-rigid registration for more accurate masking (not always working)
	   # reg_f3d -flo $2/template/$G -ref $1 -aff temp/$TEST_NAME"_"$NAME"_inv_aff" -res temp/${TEST_NAME}_${NAME}_NRR.nii.gz -cpp temp/${TEST_NAME}_${NAME}_NRR_cpp.nii.gz
	   # Resample using cpp to obtain mask candidate
	   # reg_resample -flo $2/mask/$G -ref $1 -cpp temp/${TEST_NAME}_${NAME}_NRR_cpp.nii.gz -NN -res mask/temp/$TEST_NAME"_mask_"$G
	   
	   if (( $PARAMETER_NUMBER==0 ))
		 then FIRST_PARAMETER=mask/temp/$TEST_NAME"_mask_"$G
	   else
		 MERGE_PARAMETERS=$MERGE_PARAMETERS" "mask/temp/$TEST_NAME"_mask_"$G
	   fi
	   let PARAMETER_NUMBER+=1
   fi
done
let PARAMETER_NUMBER-=1

# Label Fusion
seg_maths $FIRST_PARAMETER -merge $PARAMETER_NUMBER 4 $MERGE_PARAMETERS mask/temp/$TEST_NAME"_mask_4D.nii.gz"
seg_LabFusion -in mask/temp/$TEST_NAME"_mask_4D" -STAPLE -out mask/$TEST_NAME"_mask_STAPLE.nii.gz"
seg_maths mask/$TEST_NAME"_mask_STAPLE.nii.gz" -dil 3 mask/$TEST_NAME"_mask_STAPLE_d.nii.gz"
echo "create mask at: "mask/$TEST_NAME"_mask_STAPLE_d.nii.gz"

# rm mask/temp/*.*
# rm temp/*.*







