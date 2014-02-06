# $1: folder containing the atlas labels
# $2: folder containing the masks
QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=2.9G -l tmem=2.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

if [ ! -d $2 ]
then mkdir -p $2
fi

for G in `ls $1`
do
  LABEL=`echo "$G" | cut -d'.' -f1`
  reg_tools -in $1/$G -bin -out $2/${LABEL}.nii.gz
done
