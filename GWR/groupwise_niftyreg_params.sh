#!/bin/sh

############################################################################
###################### PARAMETERS THAT CAN BE CHANGED ######################
############################################################################
# Array that contains the input images to create the atlas
export IMG_INPUT=(`ls /home/arbaza1/scratch/morph_data/Tc1_Nick_TBM_Paper/1.1_FILES/*.nii.gz`)
export IMG_INPUT_MASK= # leave empty to not use floating masks

# template image to use to initialise the atlas creation
export TEMPLATE=`ls ${IMG_INPUT[0]}`
export TEMPLATE_MASK= # leave empty to not use a reference mask

# folder where the result images will be saved
export RES_FOLDER=`pwd`/groupwise_result_Sba

# argument to use for the affine (reg_aladin)
export AFFINE_args="-omp 8"
# argument to use for the non-rigid registration (reg_f3d)
export NRR_args="-omp 8"

# number of affine loop to perform - Note that the first step is always rigid
export AFF_IT_NUM=10
# number of non-rigid loop to perform
export NRR_IT_NUM=10

# grid engine arguments
export SBATCH_CMD="sbatch --account=rrg-mfbeg-ad --time=15:30:00 --ntasks=8 --mem-per-cpu=20G --export=ALL --mail-user=arbaza@sfu.ca --mail-type=BEGIN --mail-type=END --mail-type=FAIL --export=ALL --requeue"
############################################################################
