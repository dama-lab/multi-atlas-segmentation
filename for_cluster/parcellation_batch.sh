# Structural Parcellation shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."
# $1: folder include all the images to be parcellated
# $2: atlas folder
# $3: parcellation parameter file

export QSUB_CMD="qsub -l h_rt=5:00:00 -pe smp 1 -R y -l h_vmem=4G -l tmem=4G -l s_stack=1024M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
export QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -l h_vmem=8G -l tmem=8G -l s_stack=1024M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

#!/bin/bash
DILATE=1
ATLAS=$(basename $2)

for G in `ls $1`
do
  TEST_NAME=`echo "$G" | cut -d'.' -f1`
  NAME=`echo "$G" | cut -d'.' -f1`
  parcellation.sh $1/$G "mask/${TEST_NAME}_mask_${ATLAS}_STAPLE_d${DILATE}.nii.gz" $2 $3
done