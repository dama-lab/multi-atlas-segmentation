#!/bin/bash
#!/bin/bash

#########################################
# Demonstrate the comman usage of the
# Multi-Brain Separation (MBS) pipeline
#########################################

# Add niftk installation location to system paths: `PATH` and `LD_LIBRARY_PATH`.
# This will only work if user followed the installation instruction, and installed packages in the recommended location.
# If you installed the packages in other locations, please change the variable `$HOME` to your own installed locations.

# Option 1: if user installed the default niftk package
export PATH=${PATH}:"$HOME/niftk-18.5.4/bin"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"$HOME/niftk-18.5.4/bin"

# option 2: if use choose to compile the niftyreg/niftyseg from the source code.
export PATH=${PATH}:"$HOME/nifty_reg/bin"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}/"$HOME/nifty_reg/lib"
export PATH=${PATH}:"$HOME/nifty_seg/bin"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:"$HOME/nifty_seg/lib"

####################################
######## prepare demo data #########
####################################
# Ref: https://figshare.com/collections/Tc1_and_WT_data/3258139
# DOI: 10.6084/m9.figshare.c.3258139
# Cohort 1: https://figshare.com/articles/Tc1_and_WT_brains_cohort_1_C1_/3382693
# Cohort 2: https://figshare.com/articles/Tc1_and_WT_brains_cohort_2_C2_/3394786
HOME=$HOME
WORK_DIR=$HOME/Data/TC1
RAW_DIR=$WORK_DIR/RAW_DATA
script=$WORK_DIR/script
mkdir -p $RAW_DIR
mkdir -p $script

# get to the current directory
cd $RAW_DIR

# Get the data if not already existed/downloaded
tc1_269455=$RAW_DIR/'tc1_269455.nii.gz'
if [[ ! -e $tc1_269455 ]]; then
	wget --content-disposition -P $RAW_DIR https://ndownloader.figshare.com/files/5275453
fi

####################################
######## start demo script #########
####################################

# Download the main script if not yet done
(cd $script && svn export --force https://github.com/dancebean/multi-atlas-segmentation/trunk/MultiBrainSepsrationHelperFunctions.sh)
(cd $script && svn export --force https://github.com/dancebean/multi-atlas-segmentation/trunk/MASHelperFunctions.sh)

# source the main script (or use the location of your own copy)
source $script/MultiBrainSepsrationHelperFunctions.sh
source $script/MASHelperFunctions.sh > /dev/null 2>&1

# Alternatively, if you want to show the listing of all the available functions, use:
# source ./MASHelperFunctions.sh 

mas_quickcheck [bg_img] [(optional) overlay_img] [qc_dir] [qc_filename]
