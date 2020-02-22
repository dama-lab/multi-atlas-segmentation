export QSUB_CMD="qsub -l h_rt=1:00:00 -pe smp 1 -R y -l h_vmem=1G -l tmem=1G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error" #  -l s_stack=128M

# $1: folder containing the original images
# $2: folder containing the brain masks
# $3: folder to put the extracted brain images
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
  IMG=`echo "$G" | cut -d'.' -f1`
  ${QSUB_CMD} -N extract_$G seg_maths -in $1/${IMG} -mul $2/${IMG} -out $3/${IMG}.nii.gz
done
