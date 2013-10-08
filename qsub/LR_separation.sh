# Separate the labels into left-right hemisphere
# Step 1: make a left-right flipped version of the template image and
#         corresponding mask (Done in Matlab NIFTI Tool)
# Step 2: register the image to the flipped counterpart to get affine matrix
# Step 3: half the affine matrix
# Step 4: Apply the halved affine matrix to the original image to make it sit
#         perfectly in the middle (reg_transfer -updSform)
# Step 5: Call Matlab script to add value on the right hemisphere
#
# @Author: Ma Da (d.ma.11@ucl.ac.uk) 2013.08.06
#
# usage: LR_separation.sh $1
# $1: atlas folder (including all the flipped folder)
#     Folder structure: template - template_flipped - mask - mask_flipped
# $2: image used for LR_seperation (right half equal to 1)

# Setup default value for parameters
if [ ! -d job_output ]
then mkdir job_output
fi
if [ ! -d job_error ]
then mkdir job_error
fi
if [ ! -d $1/updSform ]
then mkdir $1/updSform
fi
if [ ! -d $1/updSform/template ]
then mkdir $1/updSform/template
fi
if [ ! -d $1/temp ]
then mkdir $1/temp
fi
if [ ! -d $1/template_middle ]
then mkdir $1/template_middle
fi
if [ ! -d $1/label_middle ]
then mkdir $1/label_middle
fi
if [ ! -d $1/mask_middle ]
then mkdir $1/mask_middle
fi
if [ ! -d $1/label_LR ]
then mkdir $1/label_LR
fi
ROOT_DIR=$(pwd)
QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=9.9G -l tmem=9.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error "
MATLAB_CMD="matlab -nosplash -logfile matlab_output.txt -r " # -nodesktop

# update template/label/mask
jid=$$ # generate random job identification number
for G in `ls $1/template/`
do
  NAME=`echo "$G" | cut -d'.' -f1` # extract file name
  jname=${NAME}_${jid}
  affine=affine_${jname} # compute the affine to transform to the flipped image
  ${QSUB_CMD} -N ${affine} reg_aladin -rigOnly -flo $1/template/$G -fmask $1/mask/$G -ref $1/template_flipped/$G -rmask $1/mask_flipped/$G -res $1/updSform/$G -aff $1"/updSform/aff_"${NAME}.txt
  half_affine=half_${jname} # half the affine matrix
  ${QSUB_CMD} -N ${half_affine} -hold_jid ${affine} reg_transform -ref $1/template/$G -halfAffine $1"/updSform/aff_"${NAME}.txt $1"/updSform/aff_"${NAME}_half.txt

#  updSform=updSform_${jname} # update template label and mask Sform to the middle position
#  updSform_template=template_${updSform}
#  ${QSUB_CMD} -N ${updSform_template} -hold_jid ${half_affine} reg_transform -ref $1/template/$G -updSform $1/template/$G $1"/updSform/aff_"${NAME}_half.txt $1/template_middle/$G
#  updSform_label=label_${updSform} # apply the half matrix to label
#  ${QSUB_CMD} -N ${updSform_label} -hold_jid ${half_affine} reg_transform -ref $1/label/$G -updSform $1/label/$G $1"/updSform/aff_"${NAME}_half.txt $1/label_middle/$G
#  updSform_mask=mask_${updSform} # apply the half matrix to mask
#  ${QSUB_CMD} -N ${updSform_mask} -hold_jid ${half_affine} reg_transform -ref $1/mask/$G -updSform $1/mask/$G $1"/updSform/aff_"${NAME}_half.txt $1/mask_middle/$G
#  updSform_LR=LR_${updSform} # apply the half matrix to the LR_seperate image
#  ${QSUB_CMD} -N ${updSform_LR} -hold_jid ${half_affine} reg_transform -ref $2 -updSform $2 $1"/updSform/aff_"${NAME}_half.txt $1/temp/LR_${NAME}.nii.gz

  resample=resample_${jname} # resample template label and mask to middle position
  resample_template=label_${resample}
  ${QSUB_CMD} -N ${resample_template} -hold_jid ${half_affine} reg_resample -NN -ref $1/template/$G -flo $1/template/$G -aff $1"/updSform/aff_"${NAME}_half.txt -res $1/template_middle/$G
  resample_label=label_${resample}
  ${QSUB_CMD} -N ${resample_label} -hold_jid ${half_affine} reg_resample -NN -ref $1/label/$G -flo $1/label/$G -aff $1"/updSform/aff_"${NAME}_half.txt -res $1/label_middle/$G
  resample_mask=mask_${resample}
  ${QSUB_CMD} -N ${resample_mask} -hold_jid ${half_affine} reg_resample -NN -ref $1/mask/$G -flo $1/mask/$G -aff $1"/updSform/aff_"${NAME}_half.txt -res $1/mask_middle/$G
  
  LR_label=LR_label_${jname} # use Matlab to seperate labels into left/right hemispheres
  ${QSUB_CMD} -N ${LR_label} -hold_jid *_${resample} ${MATLAB_CMD} "\"atlas_LR('$1/mask_middle/$G','$1/label_middle/$G','$2','$1/label_LR')\""
#  use seg_maths to calculate LR (failed because result nii img type uint18->single)   
#  right_mask=right_${jname} # calculate the right_only mask - multiply by right_half
#  ${QSUB_CMD} -N ${right_mask} -hold_jid *_${resample} seg_maths $1/mask_middle/$G -mul $2 $1/temp/r_$G
#  right_mask_20=right20_${jname} # right_only mask * 20
#  ${QSUB_CMD} -N ${right_mask_20} -hold_jid ${right_mask} seg_maths $1/temp/r_$G -mul 20 $1/temp/r20_$G
#  LR_label=LR_label_${jname} # original label + right_only mask = LR seperated label
#  ${QSUB_CMD} -N ${LR_label} -hold_jid ${right_mask_20} seg_maths $1/temp/r20_$G -add $$1/label_middle/$G $1/label_LR/$G
  
done