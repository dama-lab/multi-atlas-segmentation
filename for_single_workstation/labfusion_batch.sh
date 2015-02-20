# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# for STEPS label fusion on foler of images with registration already done

# usage: ./labfusion_batch.sh atlas $1 $2 $3 $4
# $1: folder include all the images for label fusion
# $2: atlas (in_vivo ex_vivo)
# $3: STEPS parameter k (kernel size in terms of voxel number)
# $4: STEPS parameter n (number of top ranked local atlas to select for label fusion)
ROOT_DIR=$(pwd)
# echo "Bash version ${BASH_VERSION}"
ATLAS=$(basename $2)
export QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=9.9G -l tmem=9.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

# Set STEPS parameters
if [[ ! -z $3 ]] && [[ ! -z $4 ]]; then  # if STEPS parameter is set (-z: zero = not set), so ! -z = set
  export k=$3
  export n=$4
else # if [[ -z "${STEPS_PARAMETER}" ]] set default STEPS parameter to: "4 6"
  export k=8
  export n=8
fi
export STEPS_PARAMETER="${k} ${n} "

echo "***********************************************"
echo "*   batch STEPS label fusion (STEPS) ${k} ${n}  *"
echo "***********************************************" 
# begin parcellation and dice score calculation
for H in `ls $1`
do
  TEST_NAME=`echo "$H" | cut -d'.' -f1`
  # jid_LabFusion=labfusion_"$$"
  
  seg_LabFusion -in label/${ATLAS}/${TEST_NAME}_label_4D.nii.gz \
  -STEPS ${STEPS_PARAMETER} $1/$H label/${ATLAS}/${TEST_NAME}_template_4D.nii.gz \
  -out label/${TEST_NAME}_label_${ATLAS}_STEPS_${k}_${n}.nii.gz \
  -unc -v 1
done
  