# Structural Parcellation shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)

# $1: folder include all the images to be parcellated
# $2: atlas folder
# $3: If exist, read the file to load user defined parameters (see file under sample_parameters for examples)

#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."
# export QSUB_CMD="qsub -l h_rt=2:00:00 -l h_vmem=9.9G -l tmem=9.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
# export QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -l h_vmem=14.9G -l tmem=14.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
#!/bin/bash
DILATE=1
ATLAS=$(basename $2)
MASK_FOLDER="mask" # default mask folder
MASK_SUFFIX=""
MASK_SUFFIX="_mask_${ATLAS}_STAPLE_d${DILATE}" # default mask suffix

# Read user defined parameters # need to add a line to check if $3 exist ...
if [ ! -z $3 ]; then # check if there is a 3rd argument
  if [ -f $3 ]; then # check if the file specified by 3rd argument exist
    . $3 # if file of 4th argument exist, read the parameters from the file
  fi
fi

for G in `ls $1`
do
  TEST_NAME=`echo "$G" | cut -d'.' -f1`
  NAME=`echo "$G" | cut -d'.' -f1`
  parcellation.sh $1/$G "${MASK_FOLDER}/${TEST_NAME}${MASK_SUFFIX}.nii.gz" $2 $3
done