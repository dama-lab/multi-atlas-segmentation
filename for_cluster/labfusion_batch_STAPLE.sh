# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.08.29
# for STEPS label fusion on foler of images with registration already done

# usage: ./labfusion_batch.sh atlas $1 $2 $3 $4
# $1: folder include all the images for label fusion
# $2: atlas (in_vivo ex_vivo)
ROOT_DIR=$(pwd)
# echo "Bash version ${BASH_VERSION}"
ATLAS=$(basename $2)
export QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=14.9G -l vf=14.9G -l s_stack=512M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

echo "***********************************************"
echo "*   batch STEPS label fusion (STAPLE)  *"
echo "***********************************************" 
# begin parcellation and dice score calculation
for H in `ls $1`
do
  TEST_NAME=`echo "$H" | cut -d'.' -f1`
  jid_LabFusion=labfusion_"$$"
  ${QSUB_CMD} -N ${jid_LabFusion} seg_LabFusion -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz -STAPLE -out label/${TEST_NAME}_${ATLAS}_label_STAPLE.nii.gz
done
  