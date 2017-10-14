########### job submission parameters (only needed for cluster version) ###############
# Recommended job submission parameters large FOV (e.g. 256*512*256), normally ex vivo scan normally ex vivo scan 
export QSUB_CMD="qsub -l h_rt=5:00:00 -pe smp 4 -R y -l h_vmem=1G -l tmem=1G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
export QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -pe smp 1 -R y -l h_vmem=12G -l tmem=12G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
# Recommended job submission parameters for small matrix (e.g. 192*256*96), normally in vivo scan (only necessary for cluster version)
# export QSUB_CMD="qsub -l h_rt=5:00:00 -pe smp 4 -R y -l h_vmem=1G -l tmem=1G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"
# export QSUB_SEG_MATH="qsub -l h_rt=1:00:00 -pe smp 1 -R y -l h_vmem=8G -l tmem=8G -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

################## image registration parameters #####################
# MASK_AFF: affine registration parameter for "mask.sh" (in "reg_aladin" command)
# PARCELLATION_NNR: non-rigid registration parameter for "parcellation.sh" (in "reg_f3d" command)
#######################################################################
# Recommendedecommended parameters for images with high resolution (e.g. ~50µm), normally for ex vivo high resolution images
export MASK_AFF="-ln 4 -lp 4"
export PARCELLATION_NNR="-vel -ln 4 -lp 4 -sx 0.6"
# Recommended parameters for images with high resolution (e.g. ~100µm) normally for in vivo lower resolution images
# export PARCELLATION_NNR="-ln 3 -lp 3 -sx 0.4"

############# parameters to specify brain mask files #################
# MASK_FOLDER: the folder contains brain mask files
# MASK_SUFFIX: suffix of the mask files. For instance, if the test image is "A.nii", the corresponding mask file is 
######################################################################
# default mask file name pattern, following the output of the mask.sh
export MASK_FOLDER="mask"
export MASK_SUFFIX=""

################## label fusion parameters for parcellation.sh ###################
# k: kernal size of local normallised cross correlation for atlas ranking (in seg_LabFusion -STEPS)
# n: number of top-ranked atlases selected for label fusion
# LABFUSION_OPTION: other parameters to pass to "seg_LabFusion"
#############################################################
export k=10
export n=8
export LABFUSION_OPTION="-v 1 -MRF_beta 4"
