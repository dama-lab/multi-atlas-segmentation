#!/bin/bash
####################################
######## prepare demo data #########
####################################

# (Optional) create demo directory within the current folder (preferrably an empty folder)
mkdir -p ./demo
cd ./demo

# Download the "in_vivo" atlas from: https://github.com/dancebean/mouse-brain-atlas
mkdir -p Atlas
cd Atlas
svn export https://github.com/dancebean/mouse-brain-atlas/trunk/FVB_NCrl/in_vivo/
mv in_vivo FVB_NCrl_in_vivo
# only use three atlas for fast processing and demonstration purpose
cat FVB_NCrl_in_vivo/template_list.cfg | head -n 3 > FVB_NCrl_in_vivo/template_list_demo.cfg
cd ..

# create input directory, file, and target list
mkdir -p ./input
cd ./input
target_id="A0"
svn export https://github.com/dancebean/mouse-brain-atlas/trunk/NeAt/in_vivo/template/$target_id.nii.gz
echo $target_id > targetlist.txt
cd ..

# create targetlist (only 1 file)
ls ./input | head -n 1 | cut -d. -f1 > targetlist.txt

# create output directory
mkdir -p ./output


####################################
######## start demo script #########
####################################

# Download the main script if not yet done
svn export --force https://github.com/dancebean/multi-atlas-segmentation/trunk/MASHelperFunctions.sh
# (Optional) Download the sample parameter configuration file
svn export --force https://github.com/dancebean/multi-atlas-segmentation/trunk/parameters_samples/parameter_sample.sh
# You can edit the advanced parameters to fine-tune the algorithm

# source the main script (or use the location of your own copy)
source ./MASHelperFunctions.sh
# Alternatively, if you want to mute the listing of all the available functions, use:
# source ./MASHelperFunctions.sh > /dev/null 2>&1

# define parameters
atlas_name="FVB_NCrl_in_vivo"
atlas_dir="Atlas/$atlas_name"
target_dir="input"
result_dir="output"
target_id="A0"
target_list="input/targetlist.txt"
atlas_list=$atlas_dir/template_list_demo.cfg
exe_mode=local
parameter_cfg=./parameter_sample.sh

dil_voxel=1
raw_mask_dir=$result_dir/mask
dilate_mask_dir=$result_dir/mask_dilate_$dil_voxel
mask_suffix=".mask.$atlas_name"


####################################
#### Demo script ####
####################################

# 1. ~~~~~ brain extracting/masking ~~~~~~
mas_masking_batch -T $target_dir -t $target_list -A $atlas_dir -a $atlas_list -r $result_dir -e $exe_mode # -p $parameter_cfg

# 2. ~~~~~ brain mask dilation (not always necessary, check the quickcheck images to decide) ~~~~~
mas_mask_dilate_batch $target_list $raw_mask_dir $dilate_mask_dir $mask_suffix $dil_voxel $exe_mode  # -p $parameter_cfg
# generate quickcheck for dilated mask
mas_quickcheck $target_dir/$target_id $dilate_mask_dir/$target_id$mask_suffix $result_dir/quickcheck/ \
               $target_id$mask_suffix.d_$dil_voxel # -p $parameter_cfg

# 3. ~~~~~ parcellation ~~~~~
mas_parcellation_batch -T $target_dir -t $target_list -A $atlas_dir -a $atlas_list -r $result_dir \
                       -M $dilate_mask_dir -m $mask_suffix -e local # -p $parameter_cfg

# # alternatively, if using non-dilated mask:
# mas_parcellation_batch -T $target_dir -t $target_list -A $atlas_dir -a $atlas_list -r $result_dir \
#                        -M raw_mask_dir -m $mask_suffix -e local # -p $parameter_cfg
