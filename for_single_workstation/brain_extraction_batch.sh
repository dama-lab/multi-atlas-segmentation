# $1: folder containing the original images
# $2: folder containing the brain masks
# $3: folder to put the extracted brain images

# export QSUB_CMD="qsub -l h_rt=1:00:00 -pe smp 1 -R y -l h_vmem=1G -l tmem=1G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error" #  -l s_stack=128M

if [ ! -d job_output ]
then mkdir job_output
fi
if [ ! -d job_error ]
then mkdir job_error
fi
if [ ! -d $3 ]
then mkdir -p $3
fi

for G in `ls $1`
do
  MASK=`echo "$G" | cut -d'.' -f1`
  seg_maths $1/${MASK} -mul $2/${MASK} $3/${MASK}.nii.gz
done
