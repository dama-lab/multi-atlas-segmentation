export QSUB_CMD="qsub -l h_rt=5:00:00 -pe smp 4 -R y -l h_vmem=1G -l tmem=1G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

export QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -pe smp 1 -R y -l h_vmem=12G -l tmem=12G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

export PARCELLATION_NNR="-ln 3 -lp 3 -sx 0.3"
export MASK_FOLDER="mask"
export MASK_SUFFIX=""
# export MASK_FOLDER="mask/mask_ex_vivo_LR_STEPS_3_8_d3"
#export MASK_SUFFIX="_ex_vivo_LR_label_STEPS_3_8"
export MASK_AFF="-ln 4 -lp 4"
export k=8
export n=8
export LABFUSION_OPTION="-v 1 -MRF_beta 4"
