# N4 Intensity Non-uniformity (Bias Field) Correction (Batch)
# Author: Ma Da Email: d.ma.11@ucl.ac.uk

# $1 folder containing all the images with 
# $2 folder to put the images after bias field have been corrected
# $3 (optional) folder of the masks for input image

# Setup default values for parameters
QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=3.9G -l tmem=3.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error "

if [ ! -d job_output ]; then mkdir job_output; fi
if [ ! -d job_error ]; then mkdir job_error; fi
if [ ! -f $2 ] # check if the output folder exist
  then mkdir -p $2 # if not, create the output folder (along with parents folder)
fi

jid="N4_$$"
for G in `ls $1`
do
  jname=${jid}_$G
  NAME=`echo "$G" | cut -d'.' -f1`
  INPUT_MASK=""
  if [ ! -z $3 ]; then # check if there is a 3rd argument (input mask folder)
    if [ -d $3 ]; then # check if the folder specified by 3rd argument exist
      INPUT_MASK="--inMask $3/$G"
    fi
  fi
  ${QSUB_CMD} -N ${jname} niftkN4BiasFieldCorrection -i $1/$G ${INPUT_MASK} -o $2/$G --niters 200 --convergence 0.0001 -- # -i = --inImage; -o = --outImage
done
