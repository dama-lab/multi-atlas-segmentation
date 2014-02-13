# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.7_2013.04.15 (add non-rigid registration for accurate brain extraction)
# echo "Bash version ${BASH_VERSION}..."
#!/bin/bash

# $1: enquiry image
# $2: atlas folder "in_vivo" or "ex_vivo"
# $3: if exist, read user defined parameters

# echo "*********************************************"
# echo "* Segmentation pipeline for mouse brain MRI *"
# echo "* for ${TEST_NAME} *"
# echo "*  using multi-atlas label fusion methods   *"
# echo "*         step 1 - brain extraction         *"
# echo "*********************************************"
# echo "usage: mask.sh new_image atlas_folder"

# Setup default value for parameters
ROOT_DIR=$(pwd)
QSUB_CMD="qsub -l h_rt=2:00:00 -pe smp 4 -R y -l h_vmem=1G -l tmem=1G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error " #  -l s_stack=128M
QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -pe smp 8 -R y -l h_vmem=1G -l tmem=1G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error" # -l s_stack=128M
DILATE=1 # value to be dilated for the result mask
INITIAL_AFFINE="initial_affine.txt"
MASK_AFF="-omp 4"
# Read user defined parameters # need to add a line to check if $3 exist ...
if [ ! -z $3 ]; then # check if there is a 3rd argument
  if [ -f $3 ]; then # check if the file specified by 3rd argument exist
    . $3 # if file of 4th argument exist, read the parameters from the file
  fi
fi
FULL_TEST_NAME=$(basename $1) # basename: truncate path name from the string
TEST_NAME=`echo "$FULL_TEST_NAME" | cut -d'.' -f1`
ATLAS=$(basename $2)

jid="mask_" # generate a random number as job ID "$$"
jid_folder="${jid}_folder" # creating various folders if not exist
if [ ! -f $1 ] && [ ! -f $1".nii" ] && [ ! -f $1".nii.gz" ] && [ ! -f $1".hdr" ]
  then echo "test image not exist"
fi
if [ ! -d temp ]
  then mkdir temp
fi
if [ ! -d temp/${ATLAS} ]
  then mkdir temp/${ATLAS}
fi
if [ ! -d mask ]
  then
  mkdir mask
fi
if [ ! -d mask/${ATLAS} ]
  then mkdir mask/${ATLAS}
fi
# create mask for every template image if not done yet
if [ ! -d $2/mask ]
then mkdir $2/mask
fi
# create dilated mask for every template image if not done yet
if [ ! -d $2/mask_dilate ]
then mkdir $2/mask_dilate
fi
if [ ! -d job_output ]
then mkdir job_output
fi
if [ ! -d job_error ]
then mkdir job_error
fi

# Mask back propagation
echo "Creating mask for: "$TEST_NAME
PARAMETER_NUMBER=0
jid_reg="${jid}_reg"
for G in `ls $2/template/`
do
   jname=${jid_reg}_${G}
   NAME=`echo "$G" | cut -d'.' -f1`
   # Check testing image name is different from atlas template. If same, skip (for leave-one-out)
   if [[ $2/template/$NAME != $1 ]] && [[ $2/template/$NAME.nii != $1 ]] && [[ $2/template/$NAME.nii.gz != $1 ]] && [[ $2/template/$NAME.hdr != $1 ]]
	   then
	   if [ ! -f $2/mask/$G ] && [ ! -f $2/mask/$G".nii" ] && [ ! -f $2/mask/$G".nii.gz" ] && [ ! -f $2/mask/$G".hdr" ] # if no mask for atlas, create from labels
		 then
		 jbinary="${jname}_mask_binary"
		 ${QSUB_CMD} -N ${jbinary} reg_tools -in $2/label/$G -bin -out $2/mask/$G
	   fi
	   if [ ! -f $2/mask_dilate/$G ] # if no dilated mask for atlas, create one
		 then
		 jdilate="${jname}_mask_dilate"
		 ${QSUB_CMD} -N ${jdilate} seg_maths $2/mask/$G -dil 3 $2/mask_dilate/$G
	   fi
	   # if mask & dilated mask exist, ready to preed to the affine registration step
	   j_mask_ready="${jname}_mask_ready"
	   ${QSUB_CMD} -N ${j_mask_ready} echo "get binary mask and dilated mask ready before registration"
	   
	   job_aladin="${jname}_aladin" # start create affine registration matrix
	   if [ ! -f ${INITIAL_AFFINE} ] # if no initial affine matrix file
	     then
		 ${QSUB_CMD} -hold_jid $"${jname}_mask_*" -N ${job_aladin} reg_aladin -flo $1 -ref $2/template/$G -rmask $2/mask_dilate/$G -aff temp/${ATLAS}/${TEST_NAME}_${NAME}_aff -res temp/${ATLAS}/${TEST_NAME}_${NAME}_aff.nii.gz ${MASK_AFF}
	   else # if initial affine matrix file exist, use it
	     ${QSUB_CMD} -hold_jid $"${jname}_mask_*" -N ${job_aladin} reg_aladin -flo $1 -ref $2/template/$G -rmask $2/mask_dilate/$G -inaff ${INITIAL_AFFINE} -aff temp/${ATLAS}/${TEST_NAME}_${NAME}_aff -res temp/${ATLAS}/${TEST_NAME}_${NAME}_aff.nii.gz ${MASK_AFF}
	   fi
	   job_transform="${jname}_transform"
	   ${QSUB_CMD} -hold_jid ${job_aladin} -N ${job_transform} reg_transform -ref $2/template/$G -invAff temp/${ATLAS}/${TEST_NAME}_${NAME}_aff temp/${ATLAS}/${TEST_NAME}_${NAME}_inv_aff
	   # generate mask from affine registration
	   job_resample="${jname}_resample"
	   ${QSUB_CMD} -hold_jid ${job_transform} -N ${job_resample} reg_resample -flo $2/mask/$G -ref $1 -aff temp/${ATLAS}/$TEST_NAME"_"$NAME"_inv_aff" -NN -res mask/${ATLAS}/$TEST_NAME"_mask_"$G
	   
	   # Using non-rigid registration to generate accurate mask (not always working)
	   # job_f3d="${jname}_f3d"
	   # ${QSUB_CMD} -hold_jid ${job_transform} -N ${job_f3d} reg_f3d -flo $2/template/$G -ref $1 -aff temp/${ATLAS}/${TEST_NAME}_${NAME}_inv_aff -res temp/${ATLAS}/${TEST_NAME}_${NAME}_NRR.nii.gz -cpp temp/${ATLAS}/${TEST_NAME}_${NAME}_NRR_cpp.nii.gz
	   # Resample the atlas mask to generate mask for test image
	   # job_resample="${jname}_resample"
	   # ${QSUB_CMD} -hold_jid ${job_f3d} -N ${job_resample} reg_resample -flo $2/mask/$G -ref $1 -cpp temp/${ATLAS}/${TEST_NAME}_${NAME}_NRR_cpp.nii.gz -NN -res mask/${ATLAS}/$TEST_NAME"_mask_"$G
	   
	   if (( $PARAMETER_NUMBER==0 ))
		 then FIRST_PARAMETER=mask/${ATLAS}/$TEST_NAME"_mask_"$G
	   else
		 MERGE_PARAMETERS=$MERGE_PARAMETERS" "mask/${ATLAS}/$TEST_NAME"_mask_"$G
	   fi
	   let PARAMETER_NUMBER+=1
   fi
done
let PARAMETER_NUMBER-=1

# Label Fusion
jname_merge_mask="${jid}_seg_math"
${QSUB_SEG_MATH} -hold_jid ${jid_reg}_* -N ${jname_merge_mask} seg_maths $FIRST_PARAMETER -merge $PARAMETER_NUMBER 4 $MERGE_PARAMETERS mask/${ATLAS}/${TEST_NAME}_mask_4D.nii.gz
jname_seg_LabFusion="${jid}_seg_LabFusion"
${QSUB_SEG_MATH} -hold_jid ${jname_merge_mask} -N ${jname_seg_LabFusion} seg_LabFusion -in mask/${ATLAS}/${TEST_NAME}_mask_4D -STAPLE -out mask/${TEST_NAME}_mask_${ATLAS}_STAPLE.nii.gz
export jname_dilate="${jid}_dilate"
${QSUB_CMD} -hold_jid ${jname_seg_LabFusion} -N ${jname_dilate} seg_maths mask/${TEST_NAME}_mask_${ATLAS}_STAPLE.nii.gz -dil ${DILATE} mask/${TEST_NAME}_mask_${ATLAS}_STAPLE_d${DILATE}.nii.gz
echo "creating mask at: mask/${TEST_NAME}_mask_${ATLAS}_STAPLE_d${DILATE}.nii.gz"

# rm mask/temp/*.*
# rm temp/*.*







