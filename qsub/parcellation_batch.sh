# Structural Parcellation shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.08.29 to be modified ...
#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."
# $1: folder include all the images to be parcellated
# $2: atlas folder
# $3: parcellation parameter file

QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=9.9G -l tmem=9.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error "
#!/bin/bash
DILATE=4
ATLAS=$(basename $2)

for G in `ls $1`
do
  TEST_NAME=`echo "$G" | cut -d'.' -f1`
  NAME=`echo "$G" | cut -d'.' -f1`
  parcellation.sh $1/$G "mask/${TEST_NAME}_mask_${ATLAS}_STAPLE_d${DILATE}.nii.gz" $2 $3
done