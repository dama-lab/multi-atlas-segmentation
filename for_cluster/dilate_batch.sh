QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=2.9G -l tmem=2.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

# $1: folder containing the original mask
# $2: folder containing the dilated mask
# $3: pixel to dilate
if [ ! -d job_output ]
then mkdir job_output
fi
if [ ! -d job_error ]
then mkdir job_error
fi
if [ ! -d $2 ]
then mkdir -p $2
fi

DILATE=$3

for G in `ls $1`
do
  MASK=`echo "$G" | cut -d'.' -f1`
  ${QSUB_CMD} -N dil_$G seg_maths $1/$G -dil ${DILATE} $2/${MASK}_d${DILATE}.nii.gz
done
