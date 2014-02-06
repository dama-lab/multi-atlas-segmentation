# $1: folder containing the images before apply threshold
# $2: folder containing the images after apply threshold
# $3: lower threshold
# $4: upper threshold
QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=2.9G -l tmem=2.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

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
  ${QSUB_CMD} -N thr_${G} seg_maths ${1}/${G} -thr $3 -uthr $4 ${2}/${G}
done
