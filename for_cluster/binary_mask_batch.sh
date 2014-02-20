# $1: folder containing the atlas labels
# $2: folder containing the masks
export QSUB_CMD="qsub -l h_rt=1:00:00 -pe smp 1 -R y -l h_vmem=1G -l tmem=1G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error" #  -l s_stack=128M

if [ ! -d $2 ]
then mkdir -p $2
fi

for G in `ls $1`
do
  LABEL=`echo "$G" | cut -d'.' -f1`
  ${QSUB_CMD} -N binary_mask_$G seg_maths $1/$G -bin $2/${LABEL}.nii.gz
  # reg_tools -in $1/$G -bin -out $2/${LABEL}.nii.gz # same
done
