#!/bin/bash
source $HOME/.bashrc

##########################################################
# Multi-Atlas-Segmentation, parcellation, and label fusion
# To report any bugs/request, please contact: Da Ma (da_ma@sfu.ca,d.ma.11@ucl.ac.uk)
##########################################################

# -------------------------------------------------
# define some global variables, (if not predefined)
# -------------------------------------------------
mas_script_path="$BASH_SOURCE"
mas_script_dir=${mas_script_path%/*}
mas_script_file="$(basename $mas_script_path)"
# Alternatively: mas_script_name=${mas_script_path##*/}
mas_script_name=$(echo $mas_script_file | cut -d. -f1 )

# define some default global variable value
AtlasListFileName=template_list.cfg

# define FSLDIR explicitely
# export FSLDIR="$HOME/Tools/fsl"
# source ${FSLDIR}/etc/fslconf/fsl.sh

echo """
=======================
[ $mas_script_name ]
mas_script_dir  = $mas_script_dir
mas_script_file = $mas_script_file

[ Base functions ]
# - check_image_file
# - check_atlas_file
# - check_mapping_file
# - check_label_fusion_file

# - get_orientation

[ Single processing functions ]
# - mas_masking (prerequisite: NiftyReg)
# - mas_masking_fusion (prerequisite: NiftyReg)
# - mas_mapping (prerequisite: NiftyReg)
# - mas_fusion (prerequisite: NiftySeg)
# - mas_quickcheck (prerequisite: FSL)
# - mas_label_volume (prerequisite: NiftySeg)
# - mas_template_function (template functions for developer)

[ Batch processing functions ]:
# - mas_masking_batch
# - mas_mask_dilate_batch
# - mas_mapping_batch
# - mas_fusion_batch
# - mas_parcellation_batch
# - mas_quickcheck_batch

[ Pre-processing functions ]:
# - mas_fix_header_info
# - mas_smooth_batch
# - mas_N4_batch (prerequisite: ANT)

[ Post-processing functions ]:
# - mas_extract_label
# - mas_extract_label_batch
# - mas_extract_volume
# - mas_extract_volume_batch
# - mas_quickcheck_panorama
=======================
"""


# ---------------------------------
#  function: get_orientation
# ---------------------------------
function get_orientation(){
    local function_name=${FUNCNAME[0]}
    if [ "$#" -lt 1 ]; then
        echo "Get nifti file header"
        echo "Usage: $function_name [input_img]"
        return 1
    else
        local IMG=$1
    fi

    ORIENT=`mri_info $IMG | grep Orientation`
    ORIENT=${ORIENT##*\ }
    echo $ORIENT
}

function get_orientation_batch(){
    local function_name=${FUNCNAME[0]}
    if [ "$#" -lt 2 ]; then
        echo "Get nifti file header"
        echo "Usage: $function_name [input_dir] [targetlist]"
        return 1
    else
        local input_dir=$1
        local targetlist=$2
    fi

    echo "input_dir=$input_dir"
    echo "targetlist=$targetlist"

    local target_id
    for target_id in $(cat $targetlist); do
        echo $target_id $(get_orientation $input_dir/$target_id.nii.gz)
    done
}

# ---------------------------------
#  function: check_image_file
# ---------------------------------
function check_image_file(){
	local exist_flag=0
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 1 ]]; then
		echo "[$function_name] please specify image file to check the existence"
		return 1
	fi
	local file_path=$1 # with or without image extension
	local function_name=${FUNCNAME[0]}
	
	# check existence with any valid extension
  if [[ -f $file_path ]]; then
    exist_flag=1
    return 0
    fi
  ext_array=("" ".nii" ".nii.gz" ".img" ".hdr")
  for ext in ${ext_array[@]}; do
		if [[ -f $file_path$ext ]]; then
			exist_flag=1
			break
		fi
	done
	# if find no file with any extension:
	if [[ $exist_flag -eq 0 ]]; then
		echo "[$function_name] cannot find file ($file_path)"
		return 1
	fi
	return 0
}

# ---------------------------------
#  function: check_atlas_file
# ---------------------------------
function check_atlas_file(){
	local return_flag=0
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 2 ]]; then
		echo "[$function_name] <atlas_dir> <atlas_id>"
		return_flag=1
		return $return_flag
	fi

	local atlas_dir=$1
	local atlas_id=$2

	local seg_type

	for seg_type in template label mask;do
		check_image_file "$atlas_dir/$seg_type/$atlas_id"
		if [[ $? -ne 0 ]]; then
			echo "[$function_name] ($atlas_id) atlas $seg_type missing "
			return_flag=1
			return $return_flag
		fi
	done

	return $return_flag
}

# functions to be implemented and used for input/output file checking with accurate control
function check_mapping_input(){
	local return_flag=0
	local function_name=${FUNCNAME[0]}
}
function check_mapping_output(){
	local return_flag=0
	local function_name=${FUNCNAME[0]}
}
function check_fusion_input(){
	local return_flag=0
	local function_name=${FUNCNAME[0]}
}
function check_fusion_output(){
	local return_flag=0
	local function_name=${FUNCNAME[0]}
}

# ---------------------------------
#  function: check_mapping_file
# ---------------------------------
function check_mapping_file(){
	local return_flag=0
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 4 ]]; then
		echo "[$function_name] <target_dir> <target_id> <atlas_dir> <atlas_list> <(Optional)result_dir> <(Optional)targetmask_dir> (Optional)targetmask_suffix>"
		return_flag=1
		return $return_flag
	fi

	local target_dir=$1
	local target_id=$2
	local atlas_dir=$3
	local atlas_list=$4
	local result_dir=$5
	local targetmask_dir=$6
	local targetmask_suffix=$7

	local target_id
	local atlas_name=$(basename $atlas_dir)
	local atlas_id

	# check if output file already exist
	local mapped_file_all_exist=1
	for atlas_id in $(cat $atlas_list);do
		if [[ ! -f "$result_dir/label/$atlas_name/$target_id.label.$atlas_id.nii.gz" ]] || \
		   [[ ! -f "$result_dir/mask/$atlas_name/$target_id.mask.$atlas_id.nii.gz" ]] || \
		   [[ ! -f "$result_dir/mapping/$atlas_name/$atlas_id.$target_id.f3d.nii.gz" ]]; then
		   # found missing output files
		   mapped_file_all_exist=0
		   continue
		fi
	done
	# if all file exist (no missing files found)
	if [[ $mapped_file_all_exist -eq 1 ]]; then
	   echo "[$function_name] all mapping output files exist"
	   return_flag=2
	   return $return_flag
	fi

	# check if input target file missing
	check_image_file $target_dir/$target_id
	if [[ $? -ne 0 ]]; then
		echo "[$function_name] cannot find target ($target_dir/$target_id)"
		return_flag=3
		return $return_flag
	fi
	# check if specified target mask file exist
	if [[ ! -z $targetmask_dir ]]; then
		local targetmask_name="$targetmask_dir/$target_id$targetmask_suffix"
		check_image_file $targetmask_name
		if [[ $? -ne 0 ]]; then
			echo "[$function_name] cannot find target mask $targetmask_name"
			return_flag=4
			return $return_flag
		fi
	fi
	

	return $return_flag
}

# ---------------------------------
#  function: check_label_fusion_file
# ---------------------------------
function check_label_fusion_file(){
	local return_flag=0
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 5 ]]; then
		echo "[$function_name] <target_dir> <target_id> <atlas_name> <atlas_list> <result_dir>"
		return_flag=1
		return $return_flag
	fi

	local target_dir=$1
	local target_id=$2
	local atlas_name=$3
	local atlas_list=$4
	local result_dir=$5

	# check output file
	if [[ -f $result_dir/label/$target_id.label.$atlas_name.nii.gz ]]; then
		echo "[$function_name] fusion output exist for target: $target_id, skipping ..."
		return_flag=2
		return $return_flag
	fi
	# check if input target file missing
	check_image_file $target_dir/$target_id
	local target_exist=$?
	if [[ $target_exist -ne 0 ]]; then
		echo "[$function_name] cannot find target ($target_dir/$target_id)"
		return_flag=3
		return $return_flag
	fi
	# check if the input 4D file has already been created
	local seg_file
	local seg_file_flag=1
	for seg_file in mapping label; do
		local merged_4d_file="$result_dir/$seg_file/$atlas_name/$target_id.4D.nii.gz"
		if [[ ! -f $merged_4d_file ]]; then
			seg_file_flag=0
			break			
		fi
	done
	if [[ $seg_file_flag -eq 1 ]]; then
		echo "[$function_name] ($target_id) both 4D mapping and label file, ready for fusion ..."
		return_flag=0
		return $return_flag
	fi


	# check if input mapped atlas file missing
	local atlas_flag=0
	local atlas_seg_flag=0
	local atlas_id
	for atlas_id in $(cat $atlas_list);do
		if [[ ! -f "$result_dir/mapping/$atlas_name/$atlas_id.$target_id.f3d.nii.gz" ]]; then
			# echo "[$function_name] ($target_id) Mapping file for atlas ($atlas_id) not pre-exist"
			#location:  $result_dir/mapping/$atlas_name/$atlas_id.$target_id.f3d.nii.gz"
			atlas_flag=1
			break
		fi
		local seg_file
		for seg_file in label; do # no need to check mapped mask
			if [[ ! -f "$result_dir/$seg_file/$atlas_name/$target_id.$seg_file.$atlas_id.nii.gz" ]]; then
				echo "[$function_name] ($target_id) Cannot find mapped $seg_file of atlas ($atlas_id): $result_dir/$seg_file/$atlas_name/$target_id.$seg_file.$atlas_id.nii.gz"
				atlas_seg_flag=1
				break 2
			fi
		done
	done
	# skip current $target_id if input file missing
	if [[ $atlas_flag -eq 1 ]]; then
		# echo "[$function_name] cannot fine input mapped atlas template file"
		return_flag=4
		return $return_flag
	elif [[ $atlas_seg_flag -eq 1 ]]; then
		# echo "[$function_name] cannot fine input mapped $seg_file file"
		return_flag=5
		return $return_flag
	fi
	return $return_flag
}

# ------------------------------
#  function: lable2mask
# ------------------------------
function label2masks(){
	local function_name=${FUNCNAME[0]}
	usage() {
		echo """binarize label 2 mask
		[Usage]: $function_name \$label_dir \$mask_dir [Optional]
		"""
	}
	if [[ $# -lt 2 ]]; then
		usage; return 1;
	fi

	local label_dir=$1
	local mask_dir=$2

	mkdir -p $mask_dir
	for id in $(ls $label_dir); do
		echo "create binarized mask for: $id"
		seg_maths $label_dir/$id -bin $mask_dir/$id
	done
}

# ------------------------------
#  function: dilate_mask
# ------------------------------
function dilate_masks(){
  local function_name=${FUNCNAME[0]}
  usage() {
    echo """dilate mask by [dil]
    [Usage]: $function_name \$mask_dir \$mask_dil_dir \$dil
    """
  }
  if [[ $# -lt 3 ]]; then
    usage; return 1;
  fi

  local mask_dir=$(readlink -f $1)
  local mask_dil_dir=$(readlink -f $2)
  local dil=$3

  mkdir -p $mask_dil_dir
  for id in $(ls $mask_dir); do
    echo "dilate [$dil] for mask: $id"
    seg_maths $mask_dir/$id -dil $dil $mask_dil_dir/$id
  done
}

# ------------------------------
#  function: mas_label_volume
# ------------------------------
function mas_label_volume(){
	local function_name=${FUNCNAME[0]}
	usage() {
		echo """
Multi Atlas Segmentation - Part 4: volume extraction
[$function_name] [-l target_list] [-s seg_dir] [-v vol_csv (file path)]
       (optional file name suffix) [-t seg_type] [-a atlas_name]

example usage 1: To extract the label volume for the parcellated results:
	mas_label_volume -l target_list -s result_dir/\"label\" -v vol_csv -t \"label\" -a atlas_name
example usage 2: To extract the mask volume for the parcellated results:
	mas_label_volume -l target_list -s result_dir/\"mask\" -v vol_csv -t \"mask\" -a atlas_name
		 """
		return 1
	}
	
	local OPTIND
	local options
	# print a seperate line
	echo ""

	while getopts ":l:a:s:t:v:c:h" options; do
		case $options in
			l ) echo "Target list:       $OPTARG"
				local target_list=$OPTARG;;
			a ) echo "Atlas name:        $OPTARG"
				local atlas_name=$OPTARG;;
			s ) echo "Result directory:  $OPTARG"
				local seg_dir=$OPTARG;;
			t ) echo "Segmentation type: $OPTARG"
				local seg_type=$OPTARG;;
			v ) echo "Volume file:       $OPTARG"
				local vol_csv=$OPTARG;;
			c ) echo "Cleanup flag:      $OPTARG"
				local cleanup_flag=$OPTARG;;
			\?) echo "Unknown option"
				usage; return 1;;
			h ) usage; return 1;;
			: ) usage; return 1;;
		esac
	done

	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi 

	echo "[$function_name] begin volume extraction... "
	local error_flag=0
	local target_id
	local seg_file

	# check existance of $target_list
	if [[ ! -f $target_list ]]; then
		echo "[$function_name] cannot find target_list file: $starget_list"
		error_flag=1
		return $error_flag
	fi

	# check existance of $target_id
	for target_id in $(cat $target_list); do
		seg_file="$seg_dir/$target_id"
		if [[ ! -z $seg_type ]]; then
			seg_file="$seg_file.$seg_type"
			if [[ ! -z $atlas_name ]]; then
				seg_file="$seg_file.$atlas_name"
			fi
		fi
		check_image_file $seg_file
		if [[ $? -ne 0 ]]; then
			echo "[$function_name] cannot find $seg_type file: $seg_file"
			error_flag=1
			return $error_flag
		fi
	done

	# In case output file exist, warn user before overwrite
	if [[ -f $vol_csv ]]; then
		echo "Output file: <$vol_csv> exist, overwrite?"
		local yn
		select yn in "select 1 for Yes" "select 2 for No"; do
			case $yn in
				"select 1 for Yes" ) rm -f $vol_csv; break;;
				"select 2 for No" ) echo "no overwrite, exiting ..."; return 1;;
			esac
		done
	fi

	local tmp_dir="$seg_dir/tmp_$RANDOM"
	mkdir -p $tmp_dir

	for target_id in $(cat $target_list); do
		# input image file
		seg_file="$seg_dir/$target_id"
		if [[ ! -z $seg_type ]]; then
			seg_file="$seg_file.$seg_type"
			if [[ ! -z $atlas_name ]]; then
				seg_file="$seg_file.$atlas_name"
			fi
		fi
		# output csv file
		local target_csv="$tmp_dir/$target_id.$seg_type.$atlas_name.csv"
		seg_stats $seg_file -Vl $target_csv
		# exclude the first colume, which is the background volume
		echo "$target_id,$(cat $target_csv | cut -d, -f2-)" >> $vol_csv
	done

	# remove tmp
	rm -rf $tmp_dir
}

# -------------------------
# function mas_quickcheck
# reference: 
# [1] Generating Quality Assurance Images using FSL overlay and slicer
#    https://faculty.washington.edu/madhyt/2016/12/10/180/
# -------------------------
function mas_quickcheck(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 3 ]]; then
		echo "Multi Atlas Segmentation - Part 3: quickcheck generation"
		echo "Usage: $function_name [bg_img] [(optional) overlay_img] [qc_dir] [qc_filename]"
		return 1
	fi
	
	local bg_img=$1
	local overlay_img=$2
	local qc_dir=$3
	local qc_filename=$4

	echo "bg_img      = $bg_img"
	echo "overlay_img = $overlay_img"
	echo "qc_dir      = $qc_dir"
	echo "qc_filename = $qc_filename"

	# check if FSL is installed (by checking variable $FSLDIR)
	if [[ -z $FSLDIR ]]; then
		echo "[$function_name] variable \$FSLDIR not set, cannot determine FSL installed location, exitng ..."
		return 1
	fi

	local tmp_dir=$qc_dir/tmp_$RANDOM
	mkdir -p $tmp_dir

	local bg_name=$(basename $bg_img | cut -d. -f1)
	local slicer_cmd

	if [[ ! -z $overlay_img ]]; then
		local overlay_name=$(basename $overlay_img | cut -d. -f1)
		local overlay_nan=$tmp_dir/masknan.$bg_name.$overlay_name.nii.gz
		local overlay_tmp=$tmp_dir/overlay.$bg_name.$overlay_name.nii.gz

		# determine label range
		seg_maths $overlay_img -masknan $overlay_img $overlay_nan
		local label_range=$(seg_stats $overlay_nan -r)
		echo "label_range = $label_range"
		# generate overlay nifti file using FSL's overlay
		overlay 1 0 $bg_img -a $overlay_nan $label_range $overlay_tmp

		# local label_min=$(( $(echo $label_range | cut -d' ' -f1) +1 ))
		# local label_max=$(echo $label_range | cut -d' ' -f2)
		# echo "label_range = $label_min $label_max"
		# # generate overlay nifti file using FSL's overlay
		# overlay 1 0 $bg_img -a $overlay_img $label_min $label_max $overlay_tmp

		# specify overlay transparency and colormap
		local LUT_file="$FSLDIR/etc/luts/renderjet.lut"
		if [[ ! -f $LUT_file ]]; then
			echo "[$function_name] cannot find color Look-up-table file: $LUT_file"
			return 1
		fi
		slicer_cmd="slicer -t -n -l $LUT_file"
	else # no overlay_img
		local overlay_tmp=$tmp_dir/$bg_name.nii.gz
		ln -s $bg_img $overlay_tmp
		slicer_cmd="slicer"
	fi

	# create png
	slicer_cmd="$slicer_cmd $overlay_tmp \
	  -x 0.10 $tmp_dir/x_11.png -x 0.20 $tmp_dir/x_12.png -x 0.30 $tmp_dir/x_13.png \
	  -x 0.34 $tmp_dir/x_21.png -x 0.38 $tmp_dir/x_22.png -x 0.42 $tmp_dir/x_23.png \
	  -x 0.46 $tmp_dir/x_31.png -x 0.50 $tmp_dir/x_32.png -x 0.54 $tmp_dir/x_33.png \
	  -x 0.58 $tmp_dir/x_41.png -x 0.62 $tmp_dir/x_42.png -x 0.66 $tmp_dir/x_43.png \
	  -x 0.70 $tmp_dir/x_51.png -x 0.74 $tmp_dir/x_52.png -x 0.78 $tmp_dir/x_53.png \
	  -x 0.82 $tmp_dir/x_61.png -x 0.86 $tmp_dir/x_62.png -x 0.90 $tmp_dir/x_63.png \
	  -y 0.15 $tmp_dir/y_11.png -y 0.25 $tmp_dir/y_12.png -y 0.34 $tmp_dir/y_13.png -y 0.42 $tmp_dir/y_14.png \
	  -y 0.50 $tmp_dir/y_21.png -y 0.55 $tmp_dir/y_22.png -y 0.62 $tmp_dir/y_23.png -y 0.65 $tmp_dir/y_24.png \
	  -y 0.70 $tmp_dir/y_31.png -y 0.73 $tmp_dir/y_32.png -y 0.78 $tmp_dir/y_33.png -y 0.82 $tmp_dir/y_34.png \
	  -z 0.15 $tmp_dir/z_11.png -z 0.25 $tmp_dir/z_12.png -z 0.34 $tmp_dir/z_13.png -z 0.42 $tmp_dir/z_14.png \
	  -z 0.50 $tmp_dir/z_21.png -z 0.55 $tmp_dir/z_22.png -z 0.62 $tmp_dir/z_23.png -z 0.65 $tmp_dir/z_24.png \
	  -z 0.70 $tmp_dir/z_31.png -z 0.73 $tmp_dir/z_32.png -z 0.78 $tmp_dir/z_33.png -z 0.82 $tmp_dir/z_34.png "

	 eval $slicer_cmd
	  
	# append png files -x
	  pngappend $tmp_dir/x_11.png + 2 $tmp_dir/x_12.png + 2 $tmp_dir/x_13.png $tmp_dir/x_1.png
	  pngappend $tmp_dir/x_21.png + 2 $tmp_dir/x_22.png + 2 $tmp_dir/x_23.png $tmp_dir/x_2.png
	  pngappend $tmp_dir/x_31.png + 2 $tmp_dir/x_32.png + 2 $tmp_dir/x_33.png $tmp_dir/x_3.png
	  pngappend $tmp_dir/x_41.png + 2 $tmp_dir/x_42.png + 2 $tmp_dir/x_43.png $tmp_dir/x_4.png
	  pngappend $tmp_dir/x_51.png + 2 $tmp_dir/x_52.png + 2 $tmp_dir/x_53.png $tmp_dir/x_5.png
	  pngappend $tmp_dir/x_61.png + 2 $tmp_dir/x_62.png + 2 $tmp_dir/x_63.png $tmp_dir/x_6.png

	  pngappend $tmp_dir/x_1.png + 1 $tmp_dir/x_2.png $tmp_dir/x1.png
	  pngappend $tmp_dir/x_3.png + 1 $tmp_dir/x_4.png $tmp_dir/x2.png
	  pngappend $tmp_dir/x_5.png + 1 $tmp_dir/x_6.png $tmp_dir/x3.png

	  pngappend $tmp_dir/x1.png - 2 $tmp_dir/x2.png - 2 $tmp_dir/x3.png $tmp_dir/x.png

	# append png files -y
	  pngappend $tmp_dir/y_11.png + 2 $tmp_dir/y_12.png + 2 $tmp_dir/y_13.png + 2 $tmp_dir/y_14.png $tmp_dir/y_1.png
	  pngappend $tmp_dir/y_21.png + 2 $tmp_dir/y_22.png + 2 $tmp_dir/y_23.png + 2 $tmp_dir/y_24.png $tmp_dir/y_2.png
	  pngappend $tmp_dir/y_31.png + 2 $tmp_dir/y_32.png + 2 $tmp_dir/y_33.png + 2 $tmp_dir/y_34.png $tmp_dir/y_3.png

	  pngappend $tmp_dir/y_1.png - 2 $tmp_dir/y_2.png - 2 $tmp_dir/y_3.png  $tmp_dir/y.png

	# append png files -z
	  pngappend $tmp_dir/z_11.png + 2 $tmp_dir/z_12.png + 2 $tmp_dir/z_13.png + 2 $tmp_dir/z_14.png $tmp_dir/z_1.png
	  pngappend $tmp_dir/z_21.png + 2 $tmp_dir/z_22.png + 2 $tmp_dir/z_23.png + 2 $tmp_dir/z_24.png $tmp_dir/z_2.png
	  pngappend $tmp_dir/z_31.png + 2 $tmp_dir/z_32.png + 2 $tmp_dir/z_33.png + 2 $tmp_dir/z_34.png $tmp_dir/z_3.png

	  pngappend $tmp_dir/z_1.png - 2 $tmp_dir/z_2.png - 2 $tmp_dir/z_3.png $tmp_dir/z.png
	
	# append png files -xyz
	  pngappend $tmp_dir/x.png - 2 $tmp_dir/y.png + 2 $tmp_dir/z.png $qc_dir/$qc_filename.png

	rm -rf $tmp_dir

	# To display the output image, type
	# xdg-open foo.png 
}

#-----------------------------------
# function: mas_masking
# ----------------------------------
function mas_masking(){
	local function_name=${FUNCNAME[0]}
	usage() {
		echo ""
		echo "Multi Atlas Segmentation - Preprocssing: Brain masking (brain extraction). Only affine transformation is used"
		echo "Usage: $function_name [-T target_dir] [-t target_id] [-A atlas_dir] [-a atlas_id] [-r result_dir] [-p parameter_cfg]"
		echo ""
		return 1
	}
	
	local OPTIND
	local options
	while getopts ":T:t:A:a:f:r:p:c:h" options; do
		case $options in
			T ) echo "Target directory: $OPTARG"
				local target_dir=$OPTARG;;
			t ) echo "Target ID: $OPTARG"
				local target_id=$OPTARG;;
			A ) echo "Atlas directory: $OPTARG"
				local atlas_dir=$OPTARG;;
			a ) echo "Atlas ID: $OPTARG"
				local atlas_id=$OPTARG;;
			f ) echo "Affine parameter: $OPTARG"
				local affine_param=$OPTARG;;
			r ) echo "Result directory: $OPTARG"
				local result_dir=$OPTARG;;
			p ) echo "Parameter config file: $OPTARG"
				local parameter_cfg=$OPTARG;;
			c ) echo "Cleanup flag: $OPTARG"
				local cleanup_flag=$OPTARG;;
			h ) usage; return 1;;
			\?) echo "Unknown option"
				usage; return 1;;
			: ) usage; return 1;;
		esac
	done

	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi 

	# preload parameter_cfg file
	if [[ ! -z $parameter_cfg ]]; then
		source $parameter_cfg
	fi

	echo "[$function_name] begin mapping template $atlas_id to $target_id"
	local error_flag=0

	# check mapping input/output file existance 
	# check_mapping_file $target_dir $target_id $atlas_dir $atlas_list $result_dir
	# local file_tag=$?
	# if [[ $file_tag -eq 2 ]]; then
	# 	echo "[$function_name] Mapping file already exist: $target_dir/$target_id "
	# 	return 0
	# elif [[ $file_tag -ne 0 ]]; then
	# 	echo "[$function_name] cannot find target ($target_id)"
	# 	return 1
	# fi

	# checking atlas_file existance
	check_atlas_file $atlas_dir $atlas_id
	if [[ $? -ne 0 ]]; then
		echo "[$function_name] cannot find atlas $atlas_file_type: $atlas_dir atlas_id: atlas_id"
		return 1
	fi

	# eliminate .ext from id
	# local target_id=$(echo $target_id | cut -d. -f1) # to avoid cases where there are dots ('.') in the filename
	local atlas_id=$(echo $atlas_id | cut -d. -f1)

	# creat folders
	local atlas_name=$(basename $atlas_dir)
	for subdir in tmp mapping mask label quickcheck; do
		local subdir_path="$result_dir/$subdir/$atlas_name"
		mkdir -p $subdir_path
	done

	local mapping_dir="$result_dir/mapping/$atlas_name"
	local mask_dir="$result_dir/mask/$atlas_name"
	local label_dir="$result_dir/label/$atlas_name"
	local tmp_dir="$result_dir/tmp/$atlas_name"
	mkdir -p $mapping_dir
	mkdir -p $mask_dir
	mkdir -p $label_dir
	mkdir -p $tmp_dir

	# generate affine matrix (atlas >> target), if no affine matrix found
	if [[ -f $tmp_dir/$atlas_id.$target_id.aff ]]; then
		echo "[$function_name] affine matrix already exist: $tmp_dir/$atlas_id.$target_id.aff, skipping affine step ..."
	else
		if [[ -z $affine_param ]]; then
			local affine_param="" # "-rigOnly"
		fi
		affine_param="$affine_param -speeeeed" #  -ln 4 -lp 4
		affine_param="$affine_param -flo $atlas_dir/template/$atlas_id"
		affine_param="$affine_param -fmask $atlas_dir/mask/$atlas_id"
		affine_param="$affine_param -ref $target_dir/$target_id"
		affine_param="$affine_param -res $tmp_dir/$atlas_id.$target_id.aff.nii.gz"
		affine_param="$affine_param -aff $tmp_dir/$atlas_id.$target_id.aff"

		reg_aladin $affine_param
	fi

	# check if affine matrix file generated successfully
	if [[ ! -f $tmp_dir/$atlas_id.$target_id.aff ]]; then
		echo "[$function_name] failed to generate affine matrix file"
		return 1
	fi
	# resample the label, as well as mask
	local seg_file
	for seg_file in mask; do
		local result_file="$result_dir/$seg_file/$atlas_name/$target_id.$seg_file.$atlas_id.affine.nii.gz"
		if [[ -f $result_file ]]; then
			echo "[$function_name] ($target_id) $seg_file file already exist: $result_file, skipping ..."
			continue
		fi
		local resamp_param=""
		resamp_param="$resamp_param -flo $atlas_dir/$seg_file/$atlas_id"
		resamp_param="$resamp_param -ref $target_dir/$target_id"
		resamp_param="$resamp_param -trans $tmp_dir/$atlas_id.$target_id.aff"
		resamp_param="$resamp_param -inter 0"
		resamp_param="$resamp_param -res $result_file"
		reg_resample $resamp_param 

		# generating quickcheck for mask and label
		mas_quickcheck $target_dir/$target_id $result_file $result_dir/quickcheck/$atlas_name $target_id.$seg_file.affine.$atlas_id
	done

	# remove tmp files
	if [[ $cleanup_flag -eq 1 ]]; then
		rm -rf $tmp_dir
		error_flag=$?
	fi

	# unset parameters
	unset affine_param

	return $error_flag
}

#-----------------------------------
# function: mas_mapping
# ----------------------------------
function mas_mapping(){
	local function_name=${FUNCNAME[0]}
	usage() {
		echo ""
		echo "Multi Atlas Segmentation - Part 1: Mapping"
		echo "Usage: $function_name [-T target_dir] [-t target_id] [-m target_mask] [-A atlas_dir] [-a atlas_id] [-r result_dir] [-p parameter_cfg]"
		echo ""
		return 1
	}
	
	local OPTIND
	local options
	while getopts ":T:t:m:A:a:r:p:c:h" options; do
		case $options in
			T ) echo "Target directory: $OPTARG"
				local target_dir=$OPTARG;;
			t ) echo "Target ID: $OPTARG"
				local target_id=$OPTARG;;
			m ) echo "Target mask: $OPTARG"
				local target_mask=$OPTARG;;
			A ) echo "Atlas directory: $OPTARG"
				local atlas_dir=$OPTARG;;
			a ) echo "Atlas ID: $OPTARG"
				local atlas_id=$OPTARG;;
			r ) echo "Result directory: $OPTARG"
				local result_dir=$OPTARG;;
			p ) echo "Parameter config file: $OPTARG"
				local parameter_cfg=$OPTARG;;
			c ) echo "Cleanup flag: $OPTARG"
				local cleanup_flag=$OPTARG;;
			h ) usage; return 1;;
			\?) echo "Unknown option"
				usage; return 1;;
			: ) usage; return 1;;
		esac
	done

	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi 

	# preload parameter_cfg file
	if [[ ! -z $parameter_cfg ]]; then
		source $parameter_cfg
	fi

	echo "[mas_mapping] begin mapping template $atlas_id to $target_id"
	local error_flag=0

	# check mapping input/output file existance 
	# check_mapping_file $target_dir $target_id $atlas_dir $atlas_list $result_dir
	# local file_tag=$?
	# if [[ $file_tag -eq 2 ]]; then
	# 	echo "[mas_mapping] Mapping file already exist: $target_dir/$target_id "
	# 	return 0
	# elif [[ $file_tag -ne 0 ]]; then
	# 	echo "[mas_mapping] cannot find target ($target_id)"
	# 	return 1
	# fi

	# check target_mask existance
	if [[ ! -z $target_mask ]]; then
		check_image_file $target_mask
		if [[ $? -ne 0 ]]; then
			echo "[mas_mapping] cannot find target mask for ($target_id): $target_mask"
			return 1
		fi
	# else # need to create target_mask first
	# 	mas_masking -T $target_dir -t $target_id -A $atlas_dir -a $atlas_id -r $result_dir -p $parameter_cfg
	# 	local target_mask = $result_dir/mask/$atlas_name/$target_id.mask.$atlas_id.affine.nii.gz
	fi
	# checking atlas_file existance
	check_atlas_file $atlas_dir $atlas_id
	if [[ $? -ne 0 ]]; then
		echo "[mas_mapping] cannot find atlas $atlas_file_type: $atlas_dir atlas_id: $atlas_id"
		return 1
	fi

	# eliminate .ext from id
	# local target_id=$(echo $target_id | cut -d. -f1)
	local atlas_id=$(echo $atlas_id | cut -d. -f1)

	# creat folders
	local atlas_name=$(basename $atlas_dir)
	for subdir in tmp mapping mask label quickcheck; do
		local subdir_path="$result_dir/$subdir/$atlas_name"
		mkdir -p $subdir_path
	done

	local mapping_dir="$result_dir/mapping/$atlas_name"
	local mask_dir="$result_dir/mask/$atlas_name"
	local label_dir="$result_dir/label/$atlas_name"
	local tmp_dir="$result_dir/tmp/$atlas_name"
	mkdir -p $mapping_dir
	mkdir -p $mask_dir
	mkdir -p $label_dir
	mkdir -p $tmp_dir

	# generate affine matrix (atlas >> target), if no affine matrix found
	if [[ -f $tmp_dir/$atlas_id.$target_id.aff ]]; then
		echo "[$function_name] affine matrix already exist: $tmp_dir/$atlas_id.$target_id.aff, skipping affine step ..."
	else
		# load affine_param from parameter_cfg if specified
		if [[ -z $affine_param ]]; then
			local affine_param="" # "-rigOnly"
		fi
		affine_param="$affine_param -ln 4 -lp 4 -speeeeed" #
		affine_param="$affine_param -flo $atlas_dir/template/$atlas_id"
		affine_param="$affine_param -fmask $atlas_dir/mask/$atlas_id"
		affine_param="$affine_param -ref $target_dir/$target_id"
		affine_param="$affine_param -res $tmp_dir/$atlas_id.$target_id.aff.nii.gz"
		affine_param="$affine_param -aff $tmp_dir/$atlas_id.$target_id.aff"
		# use target mask if specified
		if [[ ! -z $target_mask ]]; then
			affine_param="$affine_param -rmask $target_mask -cog"
		else
			affine_param="$affine_param -rmask $target_mask -nac"
		fi
		reg_aladin $affine_param
	fi

	# generate nrr cpp (atlas >> target), if no cpp found
	if [[ -f $tmp_dir/$atlas_id.$target_id.cpp.nii.gz ]]; then
		echo "[$function_name] non-rigid control point already exist: $tmp_dir/$atlas_id.$target_id.cpp.nii.gz, skipping non-rigid step ..."
	else
		# check if affine matrix successfully generated
		if [[ ! -f $tmp_dir/$atlas_id.$target_id.aff ]]; then
			echo "[mas_mapping] failed to generate affine matrix"
			return 1
		fi
		# load nrr_param from parameter_cfg if specified
		if [[ -z $nrr_param ]]; then
			local nrr_param="$nrr_param -vel -nogce -vel -smooF 0.04 -smooR 0.04 -ln 4 -lp 4" # -smooR 0.04 -ln 4 -lp 4
		fi
		nrr_param="$nrr_param -flo $atlas_dir/template/$atlas_id"
		nrr_param="$nrr_param -fmask $atlas_dir/mask/$atlas_id"
		nrr_param="$nrr_param -ref $target_dir/$target_id"
		# use affine transform matrix to initialize non-rigid registration
		nrr_param="$nrr_param -aff $tmp_dir/$atlas_id.$target_id.aff"
		nrr_param="$nrr_param -res $mapping_dir/$atlas_id.$target_id.f3d.nii.gz"
		nrr_param="$nrr_param -cpp $tmp_dir/$atlas_id.$target_id.cpp.nii.gz"

		if [[ ! -z $target_mask ]] ; then
			# use target mask if specified and exist
			nrr_param="$nrr_param -rmask $target_mask"
		fi
		reg_f3d $nrr_param
	fi

	# check if cpp file generated successfully
	if [[ ! -f $tmp_dir/$atlas_id.$target_id.cpp.nii.gz ]]; then
		echo "[mas_mapping] failed to generate control point cpp file"
		return 1
	fi
	# resample the label, as well as mask
	local seg_file
	for seg_file in label mask; do
		local result_file="$result_dir/$seg_file/$atlas_name/$target_id.$seg_file.$atlas_id.nii.gz"
		if [[ -f $result_file ]]; then
			echo "[$function_name] ($target_id) $seg_file file already exist: $result_file, skipping ..."
			continue
		fi
		local resamp_param=""
		resamp_param="$resamp_param -flo $atlas_dir/$seg_file/$atlas_id"
		resamp_param="$resamp_param -ref $target_dir/$target_id"
		resamp_param="$resamp_param -cpp $tmp_dir/$atlas_id.$target_id.cpp.nii.gz"
		resamp_param="$resamp_param -inter 0"
		resamp_param="$resamp_param -res $result_file"
		reg_resample $resamp_param

		# generating quickcheck for mask and label
		mas_quickcheck $target_dir/$target_id $result_file $result_dir/quickcheck/$atlas_name $target_id.$seg_file.$atlas_id
	done

	# remove tmp files
	if [[ $cleanup_flag -eq 1 ]]; then
		rm -rf $tmp_dir
		error_flag=$?
	fi

	return $error_flag
}

#-----------------------------------
# function: mas_fusion
# ----------------------------------
function mas_fusion(){
	local function_name=${FUNCNAME[0]}
	usage() {
		echo ""
		echo "Multi Atlas Segmentation - Part 2: Fusion"
		echo "Usage: $function_name [-T target_dir] [-t target_id] [-A atlas_name] [-a atlas_list] [-r result_dir]"
		echo "       (optional) [-m target_mask] [-p parameter_cfg] [-c cleanup_flag]"
		echo ""
		return 1
	}

	local OPTIND
	local options
	while getopts ":T:t:m:A:a:r:p:c:h" options; do
		case $options in
			T ) echo "Target directory: $OPTARG"
				local target_dir=$OPTARG;;
			t ) echo "Target ID: $OPTARG"
				local target_id=$OPTARG;;
			m ) echo "Target mask: $OPTARG"
				local target_mask=$OPTARG;;
			A ) echo "Atlas name: $OPTARG"
				local atlas_name=$OPTARG;;
			a ) echo "Atlas list: $OPTARG"
				local atlas_list=$OPTARG;;
			r ) echo "Result directory: $OPTARG"
				local result_dir=$OPTARG;;
			p ) echo "Parameter config file: $OPTARG"
				local parameter_cfg=$OPTARG;;
			c ) echo "Cleanup flag: $OPTARG"
				local cleanup_flag=$OPTARG;;
			h ) usage; return 1;;
			\?) echo "Unknown option"
				usage; return 1;;
			: ) usage; return 1;;
		esac
	done

	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi 

	# local target_id=$(echo $target_id | cut -d. -f1)

	local mapping_dir="$result_dir/mapping/$atlas_name"
	local mask_dir="$result_dir/mask/$atlas_name"
	local label_dir="$result_dir/label/$atlas_name"
	local tmp_dir="$result_dir/tmp/$atlas_name"
	local error_flag=0
	local k=5
	local n=8


	# checking target_file existance
	check_image_file $target_dir/$target_id
	if [[ $? -ne 0 ]]; then
		echo "[$function_name] cannot find target file $target_dir/$target_id"
		return 1
	fi

	# by default, cleanup temporary files
	if [[ -z $cleanup_flag ]]; then
		local cleanup_flag=1
	fi

	# check if $atlas_list file exist
	if [[ ! -f $atlas_list ]]; then
		echo "[$function_name] Cannot find atlas list file at: $atlas_list"
		return 1
	fi

	# check label fusion input file
	check_label_fusion_file $target_dir $target_id $atlas_name $atlas_list $result_dir
	local file_tag=$?
	if [[ $file_tag -eq 2 ]]; then
		echo "[$function_name] ($target_id) label fusion output file already exist, exiting ..."
		return 0
	elif [[ $file_tag -ne 0 ]]; then
		echo "[$function_name] ($target_id) cannot find label fusion input file"
		return 1
	fi
	# prepare parameters for label fusion
	local atlas_no=0
	for atlas_id in $(cat $atlas_list); do
		if [[ $atlas_no -eq 0 ]]; then
			local mapping_1="$mapping_dir/$atlas_id.$target_id.f3d.nii.gz"
			local mask_1="$result_dir/mask/$atlas_name/$target_id.mask.$atlas_id.nii.gz"
			local label_1="$result_dir/label/$atlas_name/$target_id.label.$atlas_id.nii.gz"
		else
			local mapping_n="$mapping_n $mapping_dir/$atlas_id.$target_id.f3d.nii.gz"
			local mask_n="$mask_n $result_dir/mask/$atlas_name/$target_id.mask.$atlas_id.nii.gz"
			local label_n="$label_n $result_dir/label/$atlas_name/$target_id.label.$atlas_id.nii.gz"
		fi
		let atlas_no+=1
	done
	let atlas_no-=1

	# prepare 4D images for label fusion if not precomputed
	local seg_file
	for seg_file in mapping label; do
		local merged_4d_file="$result_dir/$seg_file/$atlas_name/$target_id.4D.nii.gz"
		if [[ -f $merged_4d_file ]]; then
			echo "[$function_name] 4D $seg_file file exist: $merged_4d_file, skipping ..."
		else
			echo "[$function_name] prepare 4D $seg_file file for label fusion ..."
			local merge_cmd="seg_maths \$${seg_file}_1 -merge $atlas_no 4 \$${seg_file}_n $merged_4d_file"
			# echo $merge_command
			eval $merge_cmd
		fi
	done

	# label fusion
	local labfusion_param="-unc -v 1"
	labfusion_param="$labfusion_param -in $result_dir/label/$atlas_name/$target_id.4D.nii.gz"
	labfusion_param="$labfusion_param -out $result_dir/label/$target_id.label.$atlas_name.nii.gz"
	# labfusion_param="$labfusion_param -SBA"
	labfusion_param="$labfusion_param -STEPS $k $n $target_dir/$target_id $result_dir/mapping/$atlas_name/$target_id.4D.nii.gz"
	# use mask file reduce computational time for label fusion
	local merged_4d_label="$label_dir/$atlas_name/$target_id.4D.nii.gz"
	local merged_4d_mask="$mask_dir/$atlas_name/$target_id.4D.nii.gz"
	if [[ ! -z $target_mask ]] && [[ -f $target_mask ]]; then
		# use predifined mask 
		labfusion_param="$labfusion_param -mask $target_mask"
	elif [[ -f $merged_4d_label ]]; then
		# use dilated mapped labels to generate mask (majority voting)
		local targetmask_mv="$mask_dir/$target_id.mask.mv.nii.gz"
		seg_maths $merged_4d_label -tmean -bin $mask_majority_voting
		labfusion_param="$labfusion_param -mask $targetmask_mv"
	fi
	echo -e "\n [$function_name] fuse mapped template $atlas_name to parcellate $target_id ..."
	seg_LabFusion $labfusion_param

	# generate quickcheck for label
	check_image_file $result_dir/label/$target_id.label.$atlas_name.nii.gz
	if [[ $? -ne 0 ]]; then
		echo "[$function_name] ($target_id) failed to generate label file: $result_dir/label/$target_id.label.$atlas_name.nii.gz , skip quickcheck ..."
		return 1
	fi
	echo "[$function_name] generating label quickcheck for: $target_id ..."
	mas_quickcheck $target_dir/$target_id $result_dir/label/$target_id.label.$atlas_name.nii.gz $result_dir/quickcheck/ $target_id.label.$atlas_name

	# generate mask
	seg_maths $result_dir/label/$target_id.label.$atlas_name.nii.gz -bin $result_dir/mask/$target_id.mask_f3d.$atlas_name.nii.gz
	check_image_file $result_dir/mask/$target_id.mask_f3d.$atlas_name.nii.gz
	if [[ $? -ne 0 ]]; then
		echo "[$function_name] ($target_id) failed to generate mask file: $result_dir/mask/$target_id.mask_f3d.$atlas_name.nii.gz , skip quickcheck ..."
		return 1
	fi
	# generate quickcheck for mask
	echo "[$function_name] generating mask quickcheck for: $target_id ..."
	mas_quickcheck $target_dir/$target_id $result_dir/mask/$target_id.mask_f3d.$atlas_name.nii.gz $result_dir/quickcheck/ $target_id.mask_f3d.$atlas_name

	# remove tmp files
	return 0
}

# ------------------------------
# function: mas_masking_batch
# -------------------------------
function mas_masking_batch(){
	# printout function help 
	local function_name=${FUNCNAME[0]}
	usage() {
		echo ""
		echo "Multi Atlas Segmentation - Part 0: Masking (pbs generater)"
		echo "Usage: $function_name [-T target_dir] [-t target_list] [-A atlas_dir] [-r result_dir]"
		echo "       (optional) [-a atlas_list] [-p parameter_cfg] [-e execution mode (cluster/local)]"
		echo "       for [-e] option: (cluster) will submit parallel pbs jobs to cluster; (local) will run job sequentially on local machine. cluster is set by default"
		echo ""
		return 1
	}
	# get options
	local OPTIND
	local options
	while getopts ":T:t:M:s:f:A:a:r:e:p:h:" options; do
		case $options in
			T ) echo "Target directory:      $OPTARG"
				local target_dir=$OPTARG;;
			t ) echo "Target list:           $OPTARG"
				local target_list=$OPTARG;;
			M ) echo "Target mask directory: $OPTARG"
				local targetmask_dir=$OPTARG;;
			f ) echo "Target mask suffix:    $OPTARG"
				local targetmask_suffix=$OPTARG;;
			A ) echo "Atlas directory:       $OPTARG"
				local atlas_dir=$OPTARG;;
			a ) echo "Atlas list:            $OPTARG"
				local atlas_list=$OPTARG;;
			r ) echo "Result directory:      $OPTARG"
				local result_dir=$OPTARG;;
			e ) echo "Execution mode:        $OPTARG"
				local exe_mode=$OPTARG;;
			p ) echo "Parameter config file: $OPTARG"
				local parameter_cfg=$OPTARG;;
			h ) usage; return 1;;
			: ) usage; return 1;;
			\?) echo "Unknown option"
				usage; return 1;;
		esac
	done

	# check input option integrity
	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		return 1
	fi 
	# set default exe_mode to cluster
	if [[ -z $exe_mode ]]; then
		exe_mode="cluster"
	fi

	# pre-define default atlas_list if not specified
	if [[ -z $atlas_list ]]; then
		atlas_list=$atlas_dir/$AtlasListFileName
	fi

	local atlas_name=$(basename $atlas_dir)
	echo " ========================="
	echo "[$function_name] creating mask with Atlas: $atlas_name ..."
	echo "target_dir=$target_dir"
	echo "target_list=$target_list"
	echo "result_dir=$result_dir"
	echo "atlas_dir=$atlas_dir"
	echo "atlas_name=$atlas_name"
	echo "atlas_list=$atlas_list"
	echo "exe_mode=$exe_mode"
	echo " ========================="
	
	seg_file="mask" # for backward compatibility purpose, can delete

	# if in cluster mode, generate pbs related parameters/folders
	if [[ "$exe_mode" == "cluster" ]]; then
		local PBS_DIR=$result_dir/pbs
		local LOG_DIR=$result_dir/log
		local JOB_DIR=$result_dir/job
		local MEM="4gb"
		local WALLTIME="12:00:00"
		local MEM_MAPPING="4gb"
		local MEM_FUSION="8gb"
		local WALLTIME_MAPPING="12:00:00"
		local WALLTIME_FUSION="4:00:00"

		mkdir -p $PBS_DIR
		mkdir -p $LOG_DIR
		mkdir -p $JOB_DIR

		local jid="${RANDOM}_mapping" # generate random number as job ID, alternatively, use: $$
		local job_list=$JOB_DIR/$USER.$jid.$(date +%y%m%d%H%M%S).txt
		rm -f $job_list
	fi

	# start individual masking
	local target_id
	for target_id in $(cat $target_list); do
		# start individual masking
		echo "[$function_name] affine masking for target: ($target_id) ..."
		if [[ "$exe_mode" == "local" ]]; then	
			########## mapping step #################
			for atlas_id in $(cat $atlas_list); do
				# check mapping output file existance
				local result_file="$result_dir/mask/$atlas_name/$target_id.$seg_file.$atlas_id.affine.nii.gz"
				if [[ -f $result_file ]]; then
					echo "[$function_name] ($target_id) mask file already exist for atlas ($atlas_id): $result_file, skipping ..."
					continue
				fi
				local masking_cmd="mas_masking -T $target_dir -t $target_id -A $atlas_dir -a $atlas_id -r $result_dir"
				if [[ ! -z $parameter_cfg ]]; then
					masking_cmd="$masking_cmd -p $parameter_cfg"
				fi
				eval $masking_cmd
			done
			########## label fusion step ############
			echo -e "\n [$function_name] run label fusion locally for target: $target_id ... \n"
			mas_masking_fusion $target_dir $target_id $result_dir $atlas_dir $atlas_list
			# potential final step: cleanup unwanted files
		elif [[ "$exe_mode" == "cluster" ]]; then
			local job_name=$jid.$target_id
			local pbs_file=$PBS_DIR/$job_name.mapping.pbs
			local log_file=$PBS_DIR/$job_name.mapping.log
			# clean up files if pre-exist
			rm -f $pbs_file
			rm -f $log_file
			# add pbs header info
			pbsBoilerPlate -n $job_name -m $MEM_MAPPING -w $WALLTIME_MAPPING -j -O $log_file -f $pbs_file # -O /dev/null
			# calculate atlas number for job array
			readarray atlas_array < $atlas_list
			local atlas_no=$(( ${#atlas_array[@]} -1 ))
			# determine the unmapped atlas to be added to pbs job array
			local pbs_array_prefix="#PBS -t "
			for ((idx=0;idx<=$atlas_no;idx+=1)); do
				atlas_id=${atlas_array[$idx]}
				# if output files already exist, don't include from job array
				local result_file="$result_dir/mask/$atlas_name/$target_id.$seg_file.$atlas_id.affine.nii.gz"
				if [[ ! -f $result_file ]]; then
					pbs_array_prefix="${pbs_array_prefix}$idx"
					# add comma if not the last atlas
					if [[ $idx -ne $atlas_no ]]; then
						pbs_array_prefix="${pbs_array_prefix},"
					fi
				fi
			done
			# add lines to determine atlas_id from ${PBS_ARRAYID}
			echo "$pbs_array_prefix" >> $pbs_file
			echo "source $mas_script_path" >> $pbs_file
			echo "readarray atlas_array < $atlas_list" >> $pbs_file
			echo "atlas_id=\${atlas_array[\${PBS_ARRAYID}]}" >> $$pbs_file
			local masking_cmd="mas_masking -T $target_dir -t $target_id -A $atlas_dir -a $atlas_id -r $result_dir"
			if [[ ! -z $parameter_cfg ]]; then
				masking_cmd="$masking_cmd -p $parameter_cfg"
			fi
			echo -e "$masking_cmd" >> $pbs_file
			# potential final step: cleanup unwanted files

			# submit pbs job and store at joblist
			qsub $pbs_file
			echo "1,qsub $pbs_file" >> $job_list

			############# label fusion step #############
			local job_name_fusion=$jid.$target_id.fusion
			local pbs_file=$PBS_DIR/$job_name_fusion.pbs
			local log_file=$LOG_DIR/$job_name_fusion.log
			pbsBoilerPlate -n $job_name_fusion -m $MEM_FUSION -w $WALLTIME_FUSION -j -O $log_file -f $pbs_file # -O /dev/null
			if [[ ! -z $job_id_mapping ]]; then
				# if mapping job array submitted, then add job dependency
				echo "#PBS -W depend=afterokarray:$job_id_mapping" >> $pbs_file
			else
				local labfusion_mask=$result_dir/mask/$target_id.mask.$atlas_name.nii.gz
				if [[ -f $labfusion_mask ]]; then
					# all mapping already done previously, start fusion step without dependency
					echo "[$function_name] ($target_id): fusion maps without mapping job array dependency ..."
				fi

				echo "source $mas_script_path" >> $pbs_file
				echo "mas_masking_fusion $target_dir $target_id $result_dir $atlas_dir $atlas_list" >> $pbs_file
				# submit pbs job and store at joblist
				qsub $pbs_file
				echo "1,qsub $pbs_file" >> $job_list
			fi
		fi
	done

	if [[ "$exe_mode" == "cluster" ]]; then
		if [[ -f $job_list ]]; then
			echo -e "\n [$function_name] joblist created under: $job_list \n"
		else
			echo -e "\n [$function_name] no job submitted \n"
		fi
	fi
}

function mas_masking_fusion(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 3 ]]; then
		echo "Usage: $function_name [target_dir] [target_id] [result_dir] atlas_dir] [(optional) atlas_list]"
		return 1
	fi

	local target_dir=$1
	local target_id=$2
	local result_dir=$3

	local atlas_dir=$4
	local atlas_list


	if [[ ! -z $5 ]]; then
		atlas_list=$5
	else
		# pre-define default atlas_list if not specified
		atlas_list="$atlas_dir/$AtlasListFileName"
	fi

	local atlas_name=$(basename $atlas_dir)

	echo "target_dir=$target_dir"
	echo "target_id=$target_id"
	echo "result_dir=$result_dir"
	echo "atlas_dir=$atlas_dir"
	echo "atlas_name=$atlas_name"

	mask_dir="$result_dir/mask/$atlas_name"
	
	local mask_n=""
	# prepare parameters for label fusion
	local atlas_no=0
	# cloud process need to run on rcg-queen
	for atlas_id in $(cat $atlas_list); do
		if [[ $atlas_no -eq 0 ]]; then
			local mask_1="$mask_dir/$target_id.mask.$atlas_id.affine.nii.gz"
		else
			mask_n="$mask_n $mask_dir/$target_id.mask.$atlas_id.affine.nii.gz"
		fi
		let atlas_no+=1
		# mas_masking -T $target_dir -t $target_id -A $atlas_dir -a $atlas_id -r $result_dir
	done
	let atlas_no-=1
	# prepare 4D images for label fusion if not precomputed
	local merged_4d_mask="$mask_dir/$target_id.4D.nii.gz"
	if [[ -f $merged_4d_mask ]]; then
		echo "[$function_name] 4D mask(affine) exist: $merged_4d_mask, skipping ..."
	else
		echo "[$function_name] prepare 4D mask file $merged_4d_mask for label fusion ..."
		local merge_cmd="seg_maths \$mask_1 -merge $atlas_no 4 \$mask_n $merged_4d_mask"
		eval $merge_cmd
	fi
	# start brain mask label fusion
	labfusion_mask=$result_dir/mask/$target_id.mask.$atlas_name.nii.gz

	# check if brain mask label fusion has already been created
	check_image_file $labfusion_mask
	if [[ $? -eq 0 ]]; then
		echo "[$function_name] ($target_id) brain mask already exist: $labfusion_mask, skip label fusion ..."
		return 0
	fi

	local labfusion_param="-unc -v 1"
	labfusion_param="$labfusion_param -STAPLE "
	labfusion_param="$labfusion_param -in $merged_4d_mask"
	labfusion_param="$labfusion_param -out $labfusion_mask"
	echo -e "\n [$function_name] fuse mapped mask from $atlas_name for $target_id"
	seg_LabFusion $labfusion_param

	# generate quickcheck for label
	check_image_file $labfusion_mask
	if [[ $? -ne 0 ]]; then
		echo "[$function_name] ($target_id) failed to generate mask file: $labfusion_mask, skip quickcheck ..."
		return 1
	fi
	echo "[$function_name] generating mask (affine) quickcheck for: $target_id ..."
	mas_quickcheck $target_dir/$target_id $labfusion_mask $result_dir/quickcheck/ $target_id.mask.$atlas_name
}

function mas_masking_fusion_batch(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 3 ]]; then
		echo "Usage: $function_name [target_dir] [target_list] [result_dir] [(optional) atlas_dir]"
		return 1
	fi

	local target_dir=$1
	local target_list=$2
	local result_dir=$3
	if [[ ! -z $4 ]]; then
		atlas_dir=$4
	else # default $atlas_dir
		atlas_dir="/ensc/NEWTON5/STUDENTS/DMA73/Dropbox/Documents/SFU/Projects/BORG/Mouse_Brain_Atlas/NeAt_ex_vivo_LR"
	fi

	echo "target_dir=$target_dir"
	echo "target_list=$target_list"
	echo "result_dir=$result_dir"
	echo "atlas_dir=$atlas_dir"

	local target_id

	for target_id in $(cat $target_list); do
		# $$AtlasListFileName=template_list.cfg
		mas_masking_fusion $target_dir $target_id $result_dir $atlas_dir
	done
}

function mas_mapping_batch(){
	# printout function help 
	local function_name=${FUNCNAME[0]}
	usage() {
		echo ""
		echo "Multi Atlas Segmentation - Part 1: Mapping (pbs generater)"
		echo "Usage: $function_name [-T target_dir] [-t target_list] [-A atlas_dir] [-r result_dir]"
		echo "       (optional) [-M targetmask_dir] [-f targetmask_suffix] [-a atlas_list] [-p parameter_cfg] [-e execution mode (cluster/local)]"
		echo "       for [-e] option: (cluster) will submit parallel pbs jobs to cluster; (local) will run job sequentially on local machine. cluster is set by default"
		echo ""
		return 1
	}
	# get options
	local OPTIND
	local options
	while getopts ":T:t:M:s:f:A:a:r:e:p:h:" options; do
		case $options in
			T ) echo "Target directory:      $OPTARG"
				local target_dir=$OPTARG;;
			t ) echo "Target list:           $OPTARG"
				local target_list=$OPTARG;;
			M ) echo "Target mask directory: $OPTARG"
				local targetmask_dir=$OPTARG;;
			f ) echo "Target mask suffix:    $OPTARG"
				local targetmask_suffix=$OPTARG;;
			A ) echo "Atlas directory:       $OPTARG"
				local atlas_dir=$OPTARG;;
			a ) echo "Atlas list:            $OPTARG"
				local atlas_list=$OPTARG;;
			r ) echo "Result directory:      $OPTARG"
				local result_dir=$OPTARG;;
			e ) echo "Execution mode:        $OPTARG"
				local exe_mode=$OPTARG;;
			p ) echo "Parameter config file: $OPTARG"
				local parameter_cfg=$OPTARG;;
			h ) usage; return 1;;
			: ) usage; return 1;;
			\?) echo "Unknown option"
				usage; return 1;;
		esac
	done

	# check input option integrity
	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		return 1
	fi 

	# predefine some essential local variable
	local target_id
	local atlas_id
	local mas_mapping_param
	
	# check necessary input
	if [[ -z $result_dir ]]; then
		echo "[$function_name] result directory not specified"
		return 1
	fi
	if [[ -z $atlas_dir ]]; then
		echo "[$function_name] atlas directory not specified"
		return 1
	else
		local atlas_name=$(basename $atlas_dir)
	fi
	if [[ ! -f $target_list ]]; then
		echo "[$function_name] cannot find target list: $target_list"
		return 1
	fi
	# set default $atlas_list if not defined
	if [[ -z $atlas_list ]]; then
		local atlas_list=$atlas_dir/$AtlasListFileName
	fi
	# check if $atlas_list file exist
	if [[ ! -f $atlas_list ]]; then
		echo "[$function_name] Cannot find atlas list file at: $atlas_list"
		return 1
	fi
	# set execution mode as cluster by default
	if [[ -z "$exe_mode" ]]; then
		local exe_mode="cluster"
	fi
	if [[ "$exe_mode" != "cluster" ]] && [[ "$exe_mode" != "local" ]]; then
		echo "[$function_name] \$exe_mode should be either \"cluster\" or \"local\" "
		return 1
	fi

	# check atlas file
	local atlas_name=$(basename $atlas_dir)
	for atlas_id in $(cat $atlas_list);do
		check_atlas_file $atlas_dir $atlas_id
		if [[ $? -ne 0 ]]; then
			echo "[$function_name] atlas ($atlas_name: $atlas_id) file missing, exiting ..."
			return 1
		fi
	done

	# if in cluster mode, generate pbs related parameters/folders
	if [[ "$exe_mode" == "cluster" ]]; then
		local PBS_DIR=$result_dir/pbs
		local LOG_DIR=$result_dir/log
		local JOB_DIR=$result_dir/job
		local MEM="4gb"
		local WALLTIME="12:00:00"

		mkdir -p $PBS_DIR
		mkdir -p $LOG_DIR
		mkdir -p $JOB_DIR

		local jid="${RANDOM}_mapping" # generate random number as job ID, alternatively, use: $$
		local job_list=$JOB_DIR/$USER.$jid.$(date +%y%m%d%H%M%S).txt
		rm -f $job_list
	fi

	# start mapping loop
	for target_id in $(cat $target_list); do
		# check mapping input/output file existance
		check_mapping_file $target_dir $target_id $atlas_dir $atlas_list $result_dir
		local file_exist=$?
		if [[ $file_exist -eq 2 ]]; then
			echo "[$function_name] output for target $target_id exist, skipping ..."
			continue
		elif [[ $file_exist -ne 0 ]]; then
			echo "[$function_name] target $target_id file missing, skipping ..."
			continue
		fi
		# star individual mapping
		echo "[$function_name] target ($target_id) file checking success, start mapping .."
		if [[ "$exe_mode" == "local" ]]; then
			for atlas_id in $(cat $atlas_list); do
				mas_mapping_param=""
				mas_mapping_param="$mas_mapping_param -T $target_dir"
				mas_mapping_param="$mas_mapping_param -t $target_id"
				mas_mapping_param="$mas_mapping_param -A $atlas_dir"
				mas_mapping_param="$mas_mapping_param -a $atlas_id"
				mas_mapping_param="$mas_mapping_param -r $result_dir"
				# Add Optional parameters if specified
				if [[ ! -z $targetmask_dir ]]; then
					# targetmask existance already checked
					mas_mapping_param="$mas_mapping_param -m $targetmask_dir/$target_id$targetmask_suffix"
				fi
				if [[ ! -z $parameter_cfg ]]; then
					mas_mapping_param="$mas_mapping_param -p $parameter_cfg"
				fi
				if [[ ! -z $cleanup_flag ]]; then
					mas_mapping_param="$mas_mapping_param -c $cleanup_flag"
				fi

				mas_mapping $mas_mapping_param
			done
			# potential final step: cleanup unwanted files
		elif [[ "$exe_mode" == "cluster" ]]; then
			local job_name=$jid.$target_id
			local pbs_file=$PBS_DIR/$job_name.pbs
			local log_file=$LOG_DIR/$job_name.log
			# clean up files if pre-exist
			rm -f $pbs_file
			rm -f $log_file
			# add pbs header info
			pbsBoilerPlate -n $job_name -m $MEM -w $WALLTIME -j -O $log_file -f $pbs_file # -O /dev/null
			# calculate atlas number for job array
			readarray atlas_array < $atlas_list
			local atlas_no=$(( ${#atlas_array[@]} - 1 ))
			# determine the unmapped atlas to be added to pbs job array
			local pbs_array_prefix="#PBS -t " 
			for ((idx=0;idx<=$atlas_no;idx+=1));do
				atlas_id=${atlas_array[$idx]}
				# if output files already exist, don't include from job array
				if [[ ! -f "$result_dir/label/$atlas_name/$target_id.label.$atlas_id.nii.gz" ]] || \
				   [[ ! -f "$result_dir/mask/$atlas_name/$target_id.mask.$atlas_id.nii.gz" ]] || \
				   [[ ! -f "$result_dir/mapping/$atlas_name/$atlas_id.$target_id.f3d.nii.gz" ]]; then
				   pbs_array_prefix="${pbs_array_prefix}$idx"
				   # add comma if not the last atlas
				   if [[ $idx -ne $atlas_no ]]; then
						pbs_array_prefix="${pbs_array_prefix},"
				   fi
				fi
			done
			# add lines to determine atlas_id from ${PBS_ARRAYID}
			echo "$pbs_array_prefix" >> $pbs_file
			echo "source $mas_script_path" >> $pbs_file
			echo "readarray atlas_array < $atlas_list" >> $pbs_file
			echo "atlas_id=\${atlas_array[\${PBS_ARRAYID}]}" >> $pbs_file
		
			mas_mapping_param=""
			mas_mapping_param="$mas_mapping_param -T $target_dir"
			mas_mapping_param="$mas_mapping_param -t $target_id"
			mas_mapping_param="$mas_mapping_param -A $atlas_dir"
			mas_mapping_param="$mas_mapping_param -a \$atlas_id"
			mas_mapping_param="$mas_mapping_param -r $result_dir"
			
			# Add Optional parameters if specified
			if [[ ! -z $targetmask_dir ]]; then
				local targetmask_name="$targetmask_dir/$target_id$targetmask_suffix"
				check_image_file $targetmask_name
				if [[ $? -ne 0 ]]; then
					echo "[$function_name] cannot find target mask $targetmask_name"

				fi
				mas_mapping_param="$mas_mapping_param -m $targetmask_dir/$target_id$targetmask_suffix"
			fi
			if [[ ! -z $parameter_cfg ]]; then
				mas_mapping_param="$mas_mapping_param -p $parameter_cfg"
			fi
			if [[ ! -z $cleanup_flag ]]; then
				mas_mapping_param="$mas_mapping_param -c $cleanup_flag"
			fi

			echo -e "mas_mapping $mas_mapping_param" >> $pbs_file
			# potential final step: cleanup unwanted files

			# submit pbs job and store at joblist 
			qsub $pbs_file
			echo "1,qsub $pbs_file" >> $job_list
		fi
	done

	if [[ "$exe_mode" == "cluster" ]]; then
		if [[ -f $job_list ]]; then
			echo -e "\n [$function_name] joblist created under: $job_list \n"
		else
			echo -e "\n [$function_name] all output exist, no job submitted \n"
		fi
	fi
}

#-----------------------------------
# function: mas_fusion_batch
# ----------------------------------
function mas_fusion_batch(){
	# printout function help 
	local function_name=${FUNCNAME[0]}
	usage() {
		echo ""
		echo "Multi Atlas Segmentation - Part 2: fusion (pbs generater)"
		echo "Usage: $function_name [-T target_dir] [-t target_list] [-A atlas_name] [-a atlas_list] [-r result_dir]"
		echo "                       (optional) [-M targetmask_dir] [-m targetmask_suffix] [-p parameter_cfg] [-c cleanup_flag] [-e execution mode (cluster/local)]"
		echo "       for [-e] option: (cluster) will submit parallel pbs jobs to cluster; (local) will run job sequentially on local machine. cluster is set by default"
		echo ""
		return 1
	}
	# get options
	local OPTIND
	local options
	while getopts "T:t:M:m:A:a:r:p:c:e:h" options; do
		case $options in
			T ) echo "Target directory:      $OPTARG"
				local target_dir=$OPTARG;;
			t ) echo "Target list:           $OPTARG"
				local target_list=$OPTARG;;
			M ) echo "Target mask directory: $OPTARG"
				local targetmask_dir=$OPTARG;;
			m ) echo "Target mask suffix:    $OPTARG"
				local targetmask_suffix=$OPTARG;;
			A ) echo "Atlas name:            $OPTARG"
				local atlas_name=$OPTARG;;
			a ) echo "Atlas list:            $OPTARG"
				local atlas_list=$OPTARG;;
			r ) echo "Result directory:      $OPTARG"
				local result_dir=$OPTARG;;
			e ) echo "Execution mode:        $OPTARG"
				local exe_mode=$OPTARG;;
			p ) echo "Parameter config file: $OPTARG"
				local parameter_cfg=$OPTARG;;
			c ) echo "Cleanup flag:          $OPTARG"
				local cleanup_flag=$OPTARG;;
			h ) usage;;
			\?) echo "Unknown option"
				usage
				return 1;;
		esac
	done
	# check necessary input
	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi 
	if [[ -z $result_dir ]]; then
		echo "[$function_name] result directory not specified"
		return 1
	fi
	if [[ ! -f $target_list ]]; then
		echo "[$function_name] cannot find target list: $target_list"
		return 1
	fi
	# check if $atlas_list file exist
	if [[ ! -f $atlas_list ]]; then
		echo "[$function_name] Cannot find atlas list file at: $atlas_list"
		return 1
	fi
	# set execution mode as cluster by default
	if [[ -z "$exe_mode" ]]; then
		local exe_mode="cluster"
	fi
	if [[ "$exe_mode" != "cluster" ]] && [[ "$exe_mode" != "local" ]]; then
		echo "[$function_name] \$exe_mode should be either \"cluster\" or \"local\" "
		return 1
	fi

	# if in cluster mode, generate pbs related parameters/folders
	if [[ "$exe_mode" == "cluster" ]]; then
		local PBS_DIR=$result_dir/pbs
		local LOG_DIR=$result_dir/log
		local JOB_DIR=$result_dir/job
		local MEM="4gb"
		local WALLTIME="3:00:00"

		mkdir -p $PBS_DIR
		mkdir -p $LOG_DIR
		mkdir -p $JOB_DIR

		local jid="${RANDOM}_fusion" # generate random number as job ID, alternatively, use: $$
		local job_list=$JOB_DIR/$USER.$jid.$(date +%y%m%d%H%M%S).txt
		rm -f $job_list
	fi

	local target_id
	local error_flag=0

	for target_id in $(cat $target_list); do
		# check input/output files
		check_label_fusion_file $target_dir $target_id $atlas_name $atlas_list $result_dir
		local label_fusion_file_exist=$?
		if [[ $label_fusion_file_exist -eq 2 ]]; then
			echo "[$function_name] ($target_id) output file exist, skipping ..."
			continue
		elif [[ $label_fusion_file_exist -ne 0 ]]; then
			echo "[$function_name] ($target_id) input mapping file missing, skipping ..."
			continue
		fi
		# pass file checking stage
		echo "[$function_name] Input checking success, start label fusion for $target_id ..."

		# preparing label fusion parameter for $target_id
		local mas_fusion_param=""
		mas_fusion_param="$mas_fusion_param -T $target_dir"
		mas_fusion_param="$mas_fusion_param -t $target_id"
		mas_fusion_param="$mas_fusion_param -A $atlas_name"
		mas_fusion_param="$mas_fusion_param -a $atlas_list"
		mas_fusion_param="$mas_fusion_param -r $result_dir"
		# Add Optional parameters if specified
		if [[ ! -z $targetmask_dir ]]; then
			target_mask=$targetmask_dir/$target_id$targetmask_suffix
			mas_fusion_param="$mas_fusion_param -m $target_mask"
		fi
		if [[ ! -z $parameter_cfg ]]; then
			mas_fusion_param="$mas_fusion_param -p $parameter_cfg"
		fi
		if [[ ! -z $cleanup_flag ]]; then
			mas_fusion_param="$mas_fusion_param -c $cleanup_flag"
		fi

		# start label fusion based on the $exe_mode
		if [[ "$exe_mode" == "local" ]]; then
			echo "[$function_name] run label fusion locally"
			fusion_cmd="mas_fusion $mas_fusion_param"
			eval $fusion_cmd
		elif [[ "$exe_mode" == "cluster" ]]; then
			local job_name=$jid.$target_id
			local pbs_file=$PBS_DIR/$job_name.pbs
			local log_file=$LOG_DIR/$job_name.log
			pbsBoilerPlate -n $job_name -m $MEM -w $WALLTIME -j -O $log_file -f $pbs_file # -O /dev/null
			echo "source $mas_script_path" >> $pbs_file
			echo -e "mas_fusion $mas_fusion_param" >> $pbs_file
			# submit pbs job and store at joblist 
			qsub $pbs_file
			echo "1,qsub $pbs_file" >> $job_list
		fi
	done

	if [[ "$exe_mode" == "cluster" ]]; then
		if [[ -f $job_list ]]; then
			echo -e "\n [mas_fusion_pbs] joblist created under: $job_list \n"
		else
			echo -e "\n [mas_fusion_pbs] no job to submit \n"
		fi
	fi
	
	# potential final step: cleanup unwanted files
	return $error_flag
}

#-----------------------------------
# function: mas_parcellation_batch
# ----------------------------------
function mas_parcellation_batch(){
	# printout function help 
	local function_name=${FUNCNAME[0]}
	usage() {
		echo ""
		echo "Multi Atlas Segmentation - Part 1+2 pipeline: multi-atlas parcellation (= mapping + label fusion)"
		echo "Usage: $function_name [-T target_dir] [-t target_list] [-A atlas_dir] [-r result_dir]"
		echo "                       (optional) [-M targetmask_dir] [-m targetmask_suffix] [-a atlas_list] [-p parameter_cfg] [-c cleanup_flag] [-e execution mode (cluster/local)] [-y cluster_type (SGE/SLURM) SGE will be used as default if not specified"
		echo "       for [-e] option: (cluster) will submit parallel pbs jobs to cluster; (local) will run job sequentially on local machine. cluster is set by default"
		echo ""
		return 1
	}
	# get options
	local OPTIND
	local options
	while getopts "T:t:M:m:A:a:r:y:p:c:e:h" options; do
		case $options in
			T ) echo "Target directory:      $OPTARG"
				local target_dir=$OPTARG;;
			t ) echo "Target list:           $OPTARG"
				local target_list=$OPTARG;;
			M ) echo "Target mask directory: $OPTARG"
				local targetmask_dir=$OPTARG;;
			m ) echo "Target mask suffix:    $OPTARG"
				local targetmask_suffix=$OPTARG;;
			A ) echo "Atlas directory:       $OPTARG"
				local atlas_dir=$OPTARG;;
			a ) echo "Atlas list:            $OPTARG"
				local atlas_list=$OPTARG;;
			r ) echo "Result directory:      $OPTARG"
				local result_dir=$OPTARG;;
			e ) echo "Execution mode:        $OPTARG"
				local exe_mode=$OPTARG;;
			y ) echo "Cluster Type:          $OPTARG"
				local cluster_type=$OPTARG;;
			p ) echo "Parameter config file: $OPTARG"
				local parameter_cfg=$OPTARG;;
			c ) echo "Cleanup flag:          $OPTARG"
				local cleanup_flag=$OPTARG;;
			h ) usage;;
			\?) echo "Unknown option"
				usage
				return 1;;
		esac
	done

	# check necessary input
	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi 

	if [[ -z $atlas_dir ]]; then
		echo "[$function_name] no Atlas Directory specified"
		return 1
	fi
	local atlas_name=$(basename $atlas_dir)

	# check necessary input
	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi 
	if [[ -z $result_dir ]]; then
		echo "[$function_name] result directory not specified"
		return 1
	fi
	if [[ ! -f $target_list ]]; then
		echo "[$function_name] cannot find target list: $target_list"
		return 1
	fi
	# set default $atlas_list if not defined
	if [[ -z $atlas_list ]]; then
		local atlas_list=$atlas_dir/$AtlasListFileName
	fi
	# check if $atlas_list file exist
	if [[ ! -f $atlas_list ]]; then
		echo "[$function_name] Cannot find atlas list file at: $atlas_list"
		return 1
	fi

	# check atlas file
	for atlas_id in $(cat $atlas_list);do
		check_atlas_file $atlas_dir $atlas_id
		if [[ $? -ne 0 ]]; then
			echo "[$function_name] atlas ($atlas_name: $atlas_id) file missing, exiting ..."
			return 1
		fi
	done

	# set execution mode as cluster by default
	if [[ -z "$exe_mode" ]]; then
		local exe_mode="cluster"
	fi
	if [[ "$exe_mode" != "cluster" ]] && [[ "$exe_mode" != "local" ]]; then
		echo "[$function_name] \$exe_mode should be either \"cluster\" or \"local\" "
		return 1
	fi
	# set cluster type to SGE by default
	if [[ -z $cluster_type ]]; then
		local cluster_type="SGE"
	fi

	# if in cluster mode, generate pbs related parameters/folders
	if [[ "$exe_mode" == "cluster" ]]; then
		local PBS_DIR=$result_dir/pbs
		local LOG_DIR=$result_dir/log
		local JOB_DIR=$result_dir/job
		local MEM_MAPPING="4gb"
		local MEM_FUSION="8gb"
		local WALLTIME_MAPPING="12:00:00"
		local WALLTIME_FUSION="4:00:00"

		mkdir -p $PBS_DIR
		mkdir -p $LOG_DIR
		mkdir -p $JOB_DIR

		local jid="${RANDOM}_parcellation" # generate random number as job ID, alternatively, use: $$
		local job_list=$JOB_DIR/$USER.$jid.$(date +%y%m%d%H%M%S).txt
		rm -f $job_list
	fi

	local target_id
	local atlas_id
	local error_flag=0

	# start parcellation (mapping+fusion) loop
	for target_id in $(cat $target_list); do
		# check if output file already exist
		check_label_fusion_file $target_dir $target_id $atlas_name $atlas_list $result_dir
		local label_fusion_file_exist=$?
		if [[ $label_fusion_file_exist -eq 2 ]]; then
			echo "[$function_name] label fusion output file exist, skipping ..."
			continue
		fi
		# fusion parameter generated (for both local/cluster) prior to loop
		# mapping parameter generated inside the loop for local/cluster seperately)
		local mas_parcell_fusion_param=""
		mas_parcell_fusion_param="$mas_parcell_fusion_param -T $target_dir"
		mas_parcell_fusion_param="$mas_parcell_fusion_param -t $target_id"
		mas_parcell_fusion_param="$mas_parcell_fusion_param -A $atlas_name"
		mas_parcell_fusion_param="$mas_parcell_fusion_param -a $atlas_list"
		mas_parcell_fusion_param="$mas_parcell_fusion_param -r $result_dir"
		# Add Optional parameters if specified
		if [[ ! -z $targetmask_dir ]]; then
			target_mask=$targetmask_dir/$target_id$targetmask_suffix
			mas_parcell_fusion_param="$mas_parcell_fusion_param -m $target_mask"
		fi
		if [[ ! -z $parameter_cfg ]]; then
			mas_parcell_fusion_param="$mas_parcell_fusion_param -p $parameter_cfg"
		fi
		if [[ ! -z $cleanup_flag ]]; then
			mas_parcell_fusion_param="$mas_parcell_fusion_param -c $cleanup_flag"
		fi

		# start parcellation (mapping+fusion) for target $target_id
		if [[ "$exe_mode" == "local" ]]; then
			echo "[$function_name] start local parcellation for target ($target_id) ..."
			####################
			# mapping step
			for atlas_id in $(cat $atlas_list); do
				# check mapping input/output file
				check_mapping_file $target_dir $target_id $atlas_dir $atlas_list $result_dir $targetmask_dir $targetmask_suffix
				local mapping_file_exist=$?
				if [[ $mapping_file_exist -eq 2 ]]; then
					echo "[mas_mapping] Mapping output file already exist: ($target_id), skipping ..."
					continue
				elif [[ $mapping_file_exist -ne 0 ]]; then
					echo "[mas_mapping] Mapping input file missing: ($target_id), skipping"
					continue
				fi
				# start template/label mapping step
				mas_mapping_param=""
				mas_mapping_param="$mas_mapping_param -T $target_dir"
				mas_mapping_param="$mas_mapping_param -t $target_id"
				mas_mapping_param="$mas_mapping_param -A $atlas_dir"
				mas_mapping_param="$mas_mapping_param -a $atlas_id"
				mas_mapping_param="$mas_mapping_param -r $result_dir"
				# Add Optional parameters if specified
				if [[ ! -z $targetmask_dir ]]; then
					# file exsitance already checked
					targetmask_name="$targetmask_dir/$target_id$targetmask_suffix"
					mas_mapping_param="$mas_mapping_param -m $targetmask_name"
				fi
				if [[ ! -z $parameter_cfg ]]; then
					mas_mapping_param="$mas_mapping_param -p $parameter_cfg"
				fi
				if [[ ! -z $cleanup_flag ]]; then
					mas_mapping_param="$mas_mapping_param -c $cleanup_flag"
				fi
				# start mapping
				echo "[$function_name] run mapping locally for target: $target_id"
				mas_mapping $mas_mapping_param
			done
			###############################
			# label fusion step
			echo -e "\n [$function_name] run label fusion locally for target: $target_id \n"
			# echo "mas_fusion $mas_parcell_fusion_param"
			mas_fusion $mas_parcell_fusion_param
			# potential final step: cleanup unwanted files
		elif [[ "$exe_mode" == "cluster" ]]; then
			echo "[$function_name] start cluster parcellation for target: ($target_id) ..."
			####################
			# mapping step
			# check mapping input/output file
			check_mapping_file $target_dir $target_id $atlas_dir $atlas_list $result_dir $targetmask_dir $targetmask_suffix
			local mapping_file_exist=$?
			# start file checking
			if [[ $mapping_file_exist -eq 2 ]]; then
				echo "[$function_name] All mapping output file exist: ($target_id), go to fusion directly ..."
			else
				# not all mapping file pre-exist, need to run mapping step first
				if [[ $mapping_file_exist -ne 0 ]]; then
					echo "[$function_name] Mapping input file missing: ($target_id), skipping ..."
					continue
				fi
				# pass file checking, preparing qsub pbs job parameters
				local job_name_mapping=$jid.$target_id.mapping
				local pbs_file=$PBS_DIR/$job_name_mapping.pbs
				local log_file=$LOG_DIR/$job_name_mapping.log
				# clean up files if pre-exist
				rm -f $pbs_file
				rm -f $log_file
				# add pbs header info
				pbsBoilerPlate -n $job_name_mapping -m $MEM_MAPPING -w $WALLTIME_MAPPING -j -O $log_file -f $pbs_file # -O /dev/null
				# determine the unmapped atlas to be added to pbs job array
				local pbs_array_prefix="#PBS -t " 
				# calculate atlas number for job array
				readarray atlas_array < $atlas_list
				local atlas_no=${#atlas_array[@]}
				for ((idx=0;idx<$atlas_no;idx+=1));do
					atlas_id=${atlas_array[$idx]}
					# if output files already exist, don't include from job array
					if [[ ! -f "$result_dir/label/$atlas_name/$target_id.label.$atlas_id.nii.gz" ]] || \
					   [[ ! -f "$result_dir/mask/$atlas_name/$target_id.mask.$atlas_id.nii.gz" ]] || \
					   [[ ! -f "$result_dir/mapping/$atlas_name/$atlas_id.$target_id.f3d.nii.gz" ]]; then
					    pbs_array_prefix="${pbs_array_prefix}$idx,"
					    # add comma beforehand if not the first atlas
					  #   if [[ $idx -lt (( $atlas_no - 1 )) ]]; then
							# pbs_array_prefix="${pbs_array_prefix},"
					  #   fi
					fi
				done
				# cut the last comma ','
				pbs_array_prefix=$(echo $pbs_array_prefix | rev | cut -c 2- | rev)

				# add lines to determine atlas_id from ${PBS_ARRAYID}
				echo "$pbs_array_prefix" >> $pbs_file
				echo "source $mas_script_path" >> $pbs_file
				echo "readarray atlas_array < $atlas_list" >> $pbs_file
				echo "atlas_id=\${atlas_array[\${PBS_ARRAYID}]}" >> $pbs_file
			
				mas_mapping_param=""
				mas_mapping_param="$mas_mapping_param -T $target_dir"
				mas_mapping_param="$mas_mapping_param -t $target_id"
				mas_mapping_param="$mas_mapping_param -A $atlas_dir"
				mas_mapping_param="$mas_mapping_param -a \$atlas_id"
				mas_mapping_param="$mas_mapping_param -r $result_dir"
				
				# Add Optional parameters if specified
				if [[ ! -z $targetmask_dir ]]; then
					local targetmask_name="$targetmask_dir/$target_id$targetmask_suffix"
					check_image_file $targetmask_name
					if [[ $? -ne 0 ]]; then
						echo "[$function_name] cannot find target mask $targetmask_name"

					fi
					mas_mapping_param="$mas_mapping_param -m $targetmask_dir/$target_id$targetmask_suffix"
				fi
				if [[ ! -z $parameter_cfg ]]; then
					mas_mapping_param="$mas_mapping_param -p $parameter_cfg"
				fi
				if [[ ! -z $cleanup_flag ]]; then
					mas_mapping_param="$mas_mapping_param -c $cleanup_flag"
				fi

				echo -e "mas_mapping $mas_mapping_param" >> $pbs_file
				# potential final step: cleanup unwanted files

				# submit pbs job and save job in joblist
				if [[ $cluster_type == "SGE" ]]; then
					local job_id_mapping=$(qsub $pbs_file)
					echo "1,qsub $pbs_file" >> $job_list
				elif [[ $cluster_type == "SLURM" ]]; then
					local job_id_mapping=$(sbatch $pbs_file)
					echo "1,sbatch $pbs_file" >> $job_list
				else
					echo "wrong cluster type, quit ..."
					return 1
				fi
				
			fi

			###############################
			# label fusion step
			local job_name_fusion=$jid.$target_id.fusion
			local pbs_file=$PBS_DIR/$job_name_fusion.pbs
			local log_file=$LOG_DIR/$job_name_fusion.log
			pbsBoilerPlate -n $job_name_fusion -m $MEM_FUSION -w $WALLTIME_FUSION -j -O $log_file -f $pbs_file # -O /dev/null
			if [[ ! -z $job_id_mapping ]]; then
				# if mapping job array submitted, then add job dependency
				if [[ cluster_type == "SGE" ]]; then
  				echo "#PBS -W depend=afterokarray:$job_id_mapping" >> $pbs_file
  			fi
			else
				if [[ $label_fusion_file_exist -eq 0 ]]; then
					# all mapping already done previously, start fusion step without dependency
					echo "[$function_name] ($target_id): all mapping file pre-exist, start fusion job directly without job array dependency ..."
				else
					echo "[$function_name] ($target_id): no mapping job submitted, and not all mapping file pre-exist, skipping ..."
					continue
				fi
			fi

			echo "source $mas_script_path" >> $pbs_file
			echo "mas_fusion $mas_parcell_fusion_param" >> $pbs_file
			# submit pbs job and store at joblist 
			if [[ $cluster_type == "SGE" ]]; then
				qsub $pbs_file
				echo "1,qsub $pbs_file" >> $job_list
			elif [[ $cluster_type == "SLURM" ]]; then
				sbatch $pbs_file
				echo "1,sbatch $pbs_file" >> $job_list
			fi

		fi
	done

	if [[ "$exe_mode" == "cluster" ]]; then
		if [[ -f $job_list ]]; then
			echo -e "\n [$function_name] joblist created under: $job_list \n"
		else
			echo -e "\n [$function_name] no job submitted \n"
		fi
	fi

}

#-----------------------------------
# function: mas_quickcheck_batch
# ----------------------------------
function mas_quickcheck_batch(){
	# printout function help 
	local function_name=${FUNCNAME[0]}
	usage() {
	echo ""
	echo "Multi Atlas Segmentation - Part 3: Quality control (QC - Quickcheck)"
	echo "Usage: $function_name [-T target_dir] [-l target_list] [-s segmentation_dir] [-q quickcheck_dir]"
	echo "       (optional) [-y seg_type(label/mask)] [-A atlas_name] [-a atlas_list (quickcheck for mapping images)]"
	echo ""
	return 1
	}
	# get options
	local OPTIND
	local options
	while getopts "T:t:A:a:s:y:q:h" options; do
		case $options in
			T ) echo "Target directory:      $OPTARG"
				local target_dir=$OPTARG;;
			t ) echo "Target list:           $OPTARG"
				local target_list=$OPTARG;;
			A ) echo "Atlas name:            $OPTARG"
				local atlas_name=$OPTARG;;
			a ) echo "Atlas list:            $OPTARG"
				local atlas_list=$OPTARG;;
			s ) echo "segmentation dir:      $OPTARG "
				local segmentation_dir=$OPTARG;;
			y ) echo "Segmentation type:     $OPTARG"
				local seg_type=$OPTARG;;
			q ) echo "Quickcheck directory:  $OPTARG"
				local quickcheck_dir=$OPTARG;;
			h ) usage; return 1;;
			\?) echo "Unknown option"
				usage; return 1;;
		esac
	done

	local error_flag=0

	# Validate input requirement
	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi
	echo "[mas_quickcheck] start generating quickchecks"
	if [[ ! -f $target_list ]]; then
		echo "[$function_name] cannot find target list: $target_list"
		return 1
	fi

	# start generating quickcheck images
	for target_id in $(cat $target_list); do
		echo "[$function_name] overlay mapped template $atlas_id to $target_id ..."
		local bg_img="$target_dir/$target_id"
		# check existence of background image
		check_image_file $bg_img
		if [[ $? -ne 0 ]]; then
			echo "[$function_name] cannot find background image: $target_dir/$target_id"
			return 1
		fi
		# quickcheck the fusion/mapping images depending on $atlas_list
		local overlay_img
		if [[ -z $atlas_list ]]; then # quickcheck for fusion
			local quickcheck_name="$target_id"
			overlay_img="$segmentation_dir/$target_id"
			# additional file suffix for quickcheck if specified
			if [[ ! -z $seg_type ]]; then
				overlay_img="$overlay_img.$seg_type"
				if [[ ! -z $atlas_name ]]; then
					overlay_img="$overlay_img.$atlas_name"
				fi
			fi
			# check existence of overlay image
			check_image_file $overlay_img
			if [[ $? -ne 0 ]]; then
				echo "[$function_name] cannot find overlay image: $segmentation_dir/$target_id.$seg_type.$atlas_name"
				return 1
			fi
			mas_quickcheck $bg_img $overlay_img $quickcheck_dir $quickcheck_name
		else # quickcheck for all mapped atlas
			local atlas_id
			for atlas_id in $(cat $atlas_list); do
				local quickcheck_subdir="$quickcheck_dir/$atlas_name"
				mkdir -p $quickcheck_subdir
				overlay_img="$segmentation_dir/$atlas_name/$target_id.$seg_type.$atlas_id"
				check_image_file $overlay_img
				if [[ $? -ne 0 ]]; then
					echo "[$function_name] cannot find overlay image: $segmentation_dir/$atlas_name/$target_id.$seg_type.$atlas_id"
					continue
				fi
				local quickcheck_name="$target_id.$seg_type.$atlas_id"
				mas_quickcheck $bg_img $overlay_img $quickcheck_subdir $quickcheck_name
			done
		fi
	done

	return $error_flag
}

# -------------------------
# function mas_mask_dilate_batch
# -------------------------
function mas_mask_dilate_batch(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 2 ]]; then
		echo "$function_name [targetlist] [raw_mask_dir] [dilate_mask_dir] (Optionals:) [mask_suffix] [dil_voxel] [exe_mode]"
		return 1
	fi

	local targetlist=$1
	local raw_mask=$2
	local dilate_mask=$3
	local mask_suffix=$4
	local dil_voxel=$5
	local exe_mode=$6

	mkdir -p $dilate_mask
	local result_dir=$dilate_mask
	# set default dilation voxel
	if [[ -z $dil_voxel ]]; then
		dil_voxel=1
	fi
	# set default execution mode
	if [[ -z $exe_mode ]]; then
		exe_mode="local" # "cluster" #
	fi

	echo " ========================="
	echo "[$function_name] dilating mask ..."
	echo "targetlist=$targetlist"
	echo "raw_mask directory=$raw_mask"
	echo "dilate_mask directory=$dilate_mask"
	echo "mask_suffix=$mask_suffix"
	echo "dil_voxel=$dil_voxel"
	echo "exe_mode=$exe_mode"
	echo " ========================="

	# if in cluster mode, generate pbs related parameters/folders
	if [[ "$exe_mode" == "cluster" ]]; then
		local PBS_DIR=$result_dir/pbs
		local LOG_DIR=$result_dir/log
		local JOB_DIR=$result_dir/job
		local MEM="4gb"
		local WALLTIME="3:00:00"

		mkdir -p $PBS_DIR
		mkdir -p $LOG_DIR
		mkdir -p $JOB_DIR

		local jid="${RANDOM}_N4" # generate random number as job ID, alternatively, use: $$
		local job_list=$JOB_DIR/$USER.$jid.$(date +%y%m%d%H%M%S).txt
		rm -f $job_list
	fi

	local id
	for target_id in $(cat $targetlist); do
		local id=$target_id$mask_suffix
		echo "[$exe_mode] $function_name $dil_voxel voxels for $id ..."
		# local/cluster process
		if [[ "$exe_mode" == "local" ]]; then
			seg_maths $raw_mask/$id.nii.gz -dil $dil_voxel $dilate_mask/$id.nii.gz
		elif [[ "$exe_mode" == "cluster" ]]; then
			local job_name=$jid.$target_id
			local pbs_file=$PBS_DIR/$job_name.pbs
			local log_file=$LOG_DIR/$job_name.log
			# clean up files if pre-exist
			rm -f $pbs_file
			rm -f $log_file
			# add pbs header info
			pbsBoilerPlate -n $job_name -m $MEM -w $WALLTIME -j -O $log_file -f $pbs_file # -O /dev/null
			echo "seg_maths $raw_mask/$id.nii.gz -dil $dil_voxel $dilate_mask/$id.nii.gz" >> $pbs_file
			qsub $pbs_file
			echo "1,qsub $pbs_file" >> $job_list
		fi
	done
}

#-----------------------------------
# function: mas_create_atlas
# ----------------------------------
function mas_create_atlas(){
	# - mas_create_atlas (prerequisite: NiftyReg for mask dilation, to-do)
	local function_name=${FUNCNAME[0]}
	usage(){
		echo """
		Creating atlas folders from the Multi-Atlas-Segmentation result (TBA)
		Usage: $function_name [-T target_dir] [-t target_list] [-O old_atlas_name] [-L label_dir] [-M mask_dir] [-N new_atlas_dir]
		"""
		return 1
	}
	local OPTIND
	local options
	while getopts ":T:t:O:L:M:N" options; do
		case $options in
			T ) echo "Target directory:    $OPTARG"
				local target_dir=$OPTARG;;
			t ) echo "Target list:         $OPTARG"
				local target_list=$OPTARG;;
			O ) echo "Old atlas name:      $OPTARG"
				local old_atlas_name=$OPTARG;;
			L ) echo "Label directory:     $OPTARG"
				local label_dir=$OPTARG;;
			M ) echo "Mask directory:      $OPTARG"
				local mask_dir=$OPTARG;;
			N ) echo "New atlas directory: $OPTARG"
				local new_atlas_dir=$OPTARG;;
			h ) usage; return 1;;
			\?) echo "Unkown option"
				usage; return 1;;
			: ) usage; return 1;;
		esac
	done

	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi

	# check the existance of input files
	for target_id in $(cat $target_list); do
		# checking target file
		check_image_file $target_dir/$target_id
		if [[ $? -ne 0 ]]; then
			echo "[$function_name] cannot find target file: $target_dir/$target_id"
			return 1
		fi
		local seg_type
		# checking label/masking files
			# to be completed
	done

}

#-----------------------------------
# function: mas_template_function
# ----------------------------------
function mas_template_function(){
	# printout function help 
	local function_name=${FUNCNAME[0]}
	usage_test() {
		echo ""
		echo "Multi Atlas Segmentation - testing"
		echo "Usage: $function_name [-T target_dir] [-t target_list] [-m target_mask] [-A atlas_dir] [-a atlas_list] [-r result_dir] [-p parameter_cfg] [-c cleanup_flag (optional)]"
		echo ""
		return 1
	}
	# get options
	local OPTIND
	local options
	while getopts ":T:t:m:A:a:r:p:c:h" options; do
		case $options in
			T ) echo "Target directory: $OPTARG"
				target_dir=$OPTARG;;
			t ) echo "Target ID: $OPTARG"
				target_id=$OPTARG;;
			m ) echo "Target mask: $OPTARG"
				target_mask=$OPTARG;;
			A ) echo "Atlas directory: $OPTARG"
				atlas_dir=$OPTARG;;
			a ) echo "Atlas list: $OPTARG"
				atlas_list=$OPTARG;;
			r ) echo "Result directory: $OPTARG"
				result_dir=$OPTARG;;
			p ) echo "Parameter config file: $OPTARG"
				parameter_cfg=$OPTARG;;
			c ) echo "Cleanup flag: $OPTARG"
				cleanup_flag=$OPTARG;;
			h ) usage_test; return 1;;
			\?) echo "Unknown option"
				usage_test; return 1;;
			: ) usage; return 1;;
		esac

		if [[ $OPTIND -eq 1 ]]; then
			echo "[$function_name] no option specified"
			return 1
		fi 

done
}

#-----------------------------------
# Other pre-/post-processing function
# ----------------------------------
function mas_fix_header_info(){
	local function_name=${FUNCNAME[0]}
    if [[ $# -lt 3 ]]; then
		echo "$function_name Usage: $function_name [Input_file with wrong header] [orientation] [Output_file] [(Optional) output_type (analyze/nii)]"
		return 1
    fi

    local input_file=$1
    local orientation=$2
    local output_file=$3
    local output_type
    if [[ ! -z $4 ]]; then
    	output_type=$4
    else
    	output_type=nii
    fi

    mri_convert --in_orientation $orientation --out_orientation $orientation -ot $output_type $input_file $3 # -odt float
}

function mas_extract_label(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 4 ]]; then
		echo "Usage: $function_name [parcellation_dir] [target_id] [label] [result_dir] [(optional) label_suffix] [(optional) extracted_label_suffix]"
		return 1
	fi

	local parcellation_dir=$1
	local target_id=$2
	local label=$3
	local result_dir=$4
	local label_suffix=$5
	local extracted_label_suffix=$6

	seg_maths $parcellation_dir/$target_id$label_suffix.nii.gz -thr $(($label-1)) -uthr $(($label+1)) $result_dir/$target_id$extracted_label_suffix.nii.gz
}

function mas_extract_label_batch(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 4 ]]; then
		echo "Usage: $function_name [parcellation_dir] [target_list] [label] [result_dir] [(optional) label_suffix] [(optional) extracted_label_suffix]"
		return 1
	fi

	local parcellation_dir=$1
	local target_list=$2
	local label=$3
	local result_dir=$4
	local label_suffix=$5
	local extracted_label_suffix=$6

	for target_id in $(cat $target_list); do
		mas_extract_label $parcellation_dir $target_id $label $result_dir $label_suffix $extracted_label_suffix
	done
}

function mas_extract_volume(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 3 ]]; then
		echo "Usage: $function_name [parcellation_dir] [target_id] [label] [(optional) label_suffix]"
		return 1
	fi

	local parcellation_dir=$1
	local target_id=$2
	local label=$3
	local label_suffix=$4

	seg_stats "$parcellation_dir/$target_id$label_suffix.nii.gz" -vl | grep $label | cut -d' ' -f3
}

function mas_extract_volume_batch(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 4 ]]; then
		echo "Usage: $function_name [parcellation_dir] [target_list] [label] [result_csv] [(optional) label_suffix]"
		return 1
	fi

	local parcellation_dir=$1
	local target_list=$2
	local label=$3
	local result_csv=$4
	local label_suffix=$5

	if [[ -f $result_csv ]]; then
		echo "Output file: <$result_csv> exist, overwrite?"
		local yn
		select yn in "select 1 for Yes" "select 2 for No"; do
			case $yn in
				"select 1 for Yes" ) rm -f $result_csv; break;;
				"select 2 for No" ) echo "no overwrite, exiting ..."; return 1;;
			esac
		done
	fi

	echo "Target_ID,Volume" >> $result_csv
	for target_id in $(cat $target_list); do
		echo "$target_id,$(mas_extract_volume $parcellation_dir $target_id $label $label_suffix)" >> $result_csv
	done
}

function mas_quickcheck_panorama(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 2 ]]; then
		echo "Usage: $function_name [target_dir] [targetlist] [qc_dir] [(option) label_dir] [(option) label_suffix] [(optional) target_name]"
		return 1
	fi

	local target_dir=$1
	local targetlist=$2
	local qc_dir=$3
	local label_dir=$4
	local label_suffix=$5
	local target_name=$6	

	if [[ -z $target_name ]]; then
		target_name=$(basename $target_dir)
	fi

	echo """
target_dir=$target_dir
qc_dir=$qc_dir
label_dir=$label_dir
label_suffix=$label_suffix
targetlist=$targetlist
target_name=$target_name
	"""

	mkdir -p $qc_dir

	local target_id
	local target_no=0
	local pngappend_parameter
	for target_id in $(cat $targetlist); do
		local tmp_dir=$qc_dir/tmp_${RANDOM}
		mkdir -p $tmp_dir
		local LUT_file="$FSLDIR/etc/luts/renderjet.lut"
		if [[ ! -f $LUT_file ]]; then
			echo "[$function_name] cannot find color Look-up-table file: $LUT_file"
			return 1
		fi
		echo "$target_no. quickcheck for $target_id"

		local slicer_1st_parameter
		if [[ ! -z $label_dir ]]; then
			# overlay
			local bg_img=$target_dir/$target_id.nii.gz
			local overlay_img=$label_dir/$target_id$label_suffix.nii.gz
			local bg_name=$(basename $bg_img | cut -d. -f1)
			local overlay_name=$(basename $overlay_img | cut -d. -f1)
			local overlay_nan=$tmp_dir/masknan.$bg_name.$overlay_name.nii.gz
			local overlay_tmp=$tmp_dir/overlay.$bg_name.$overlay_name.nii.gz

			# determine label range
			seg_maths $overlay_img -masknan $overlay_img $overlay_nan
			local label_range=$(seg_stats $overlay_nan -r)
			echo "label_range = $label_range"
			# generate overlay nifti file using FSL's overlay
			overlay 1 0 $bg_img -a $overlay_nan $label_range $overlay_tmp
			local LUT_file="$FSLDIR/etc/luts/renderjet.lut"
			if [[ ! -f $LUT_file ]]; then
				echo "[$function_name] cannot find color Look-up-table file: $LUT_file"
				return 1
			fi
			slicer_1st_parameter="-t -n -l $LUT_file $overlay_tmp"
		else
			# no overlay
			slicer_1st_parameter=$target_dir/$target_id.nii.gz
		fi
		slicer $slicer_1st_parameter \
			-x 0.4 $tmp_dir/x_1.png -x 0.5 $tmp_dir/x_2.png -x 0.6 $tmp_dir/x_3.png \
			-y 0.3 $tmp_dir/y_1.png -y 0.4 $tmp_dir/y_2.png -y 0.5 $tmp_dir/y_3.png \
			-z 0.4 $tmp_dir/z_1.png -z 0.5 $tmp_dir/z_2.png -z 0.6 $tmp_dir/z_3.png
		# append pngs
		pngappend $tmp_dir/x_1.png - 2 $tmp_dir/x_2.png - 2 $tmp_dir/x_3.png $tmp_dir/x.png
		pngappend $tmp_dir/y_1.png - 2 $tmp_dir/y_2.png - 2 $tmp_dir/y_3.png $tmp_dir/y.png
		pngappend $tmp_dir/z_1.png - 2 $tmp_dir/z_2.png - 2 $tmp_dir/z_3.png $tmp_dir/z.png
		pngappend $tmp_dir/x.png   - 2 $tmp_dir/y.png   - 2 $tmp_dir/z.png   $qc_dir/$target_id.png
		rm -rf $tmp_dir

		if [[ $target_no -eq 0 ]]; then
			pngappend_parameter="$qc_dir/$target_id.png"
		elif [[ $target_no -gt 0 ]]; then
			pngappend_parameter="$pngappend_parameter + 2 $qc_dir/$target_id.png"
		fi
		(( target_no+=1 ))
	done
	pngappend $pngappend_parameter $qc_dir/$target_name.png
}


function mas_smooth_batch(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 2 ]]; then
		echo "[$function_name] [input_dir] [target_list] [result_dir] [(optional) exe_mode]"
		return 1
	fi
	local input_dir=$1
	local target_list=$2
	local result_dir=$3
	local exe_mode=$4

	local N4_parameter

	# set default execution mode
	if [[ -z $exe_mode ]]; then
		exe_mode="local" # "cluster" #
	fi

	echo "input_dir = $input_dir"
	echo "result_dir = $result_dir"
	echo "target_list = $target_list"
	echo "exe_mode = $exe_mode"

	mkdir -p $result_dir

	# if in cluster mode, generate pbs related parameters/folders
	if [[ "$exe_mode" == "cluster" ]]; then
		local PBS_DIR=$result_dir/pbs
		local LOG_DIR=$result_dir/log
		local JOB_DIR=$result_dir/job
		local MEM="4gb"
		local WALLTIME="3:00:00"

		mkdir -p $PBS_DIR
		mkdir -p $LOG_DIR
		mkdir -p $JOB_DIR

		local jid="${RANDOM}_N4" # generate random number as job ID, alternatively, use: $$
		local job_list=$JOB_DIR/$USER.$jid.$(date +%y%m%d%H%M%S).txt
		rm -f $job_list
	fi

	local target_id
	for target_id in $(cat $target_list); do

		local resolution=$(mri_info $input_dir/$target_id.nii.gz | grep "voxel sizes:" | cut -d: -f2)
		local resolution_x=$(echo $resolution | cut -d, -f1)
		local resolution_y=$(echo $resolution | cut -d, -f2)
		local resolution_z=$(echo $resolution | cut -d, -f3)

		if [[ "$exe_mode" == "local" ]]; then
			echo "<$exe_mode> smoS_nii: $target_id ..."
			reg_tools -in $input_dir/$target_id.nii.gz -out $result_dir/$target_id.nii.gz -smoS $resolution_x $resolution_y $resolution_z
		elif [[ "$exe_mode" == "cluster" ]]; then
			echo "<$exe_mode> smoS_nii: $target_id ..."
			local job_name=$jid.$target_id
			local pbs_file=$PBS_DIR/$job_name.pbs
			local log_file=$LOG_DIR/$job_name.log
			# clean up files if pre-exist
			rm -f $pbs_file
			rm -f $log_file
			# add pbs header info
			pbsBoilerPlate -n $job_name -m $MEM -w $WALLTIME -j -O $log_file -f $pbs_file # -O /dev/null
			echo "reg_tools -in $input_dir/$target_id.nii.gz -out $result_dir/$target_id.nii.gz -smoS $resolution_x $resolution_y $resolution_z" >> $pbs_file
			qsub $pbs_file
			echo "1,qsub $pbs_file" >> $job_list
		fi
	done
}

function mas_N4_batch(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 2 ]]; then
		echo "[$function_name] [input_dir] [target_list] [result_dir] (optional) [exe_mode] [mask_flag] [mask_dir] [mask_suffix]"
		echo "    [Important] assuming target_list doesn include suffix, and file extension is nii.gz"
		return 1
	fi
	local input_dir=$1
	local target_list=$2
	local result_dir=$3
	local exe_mode=$4
	local mask_flag=$5
	local mask_dir=$6
	local mask_suffix=$7

	local N4_parameter

	mkdir -p $result_dir

	# set flag = 1 if using mask
	if [[ -z $mask_flag ]]; then
		mask_flag=0 # or 1 if no mask
	fi
	# set default execution mode
	if [[ -z $exe_mode ]]; then
		exe_mode="local" # "cluster" #
	fi

	# if in cluster mode, generate pbs related parameters/folders
	if [[ "$exe_mode" == "cluster" ]]; then
		local PBS_DIR=$result_dir/pbs
		local LOG_DIR=$result_dir/log
		local JOB_DIR=$result_dir/job
		local MEM="4gb"
		local WALLTIME="3:00:00"

		mkdir -p $PBS_DIR
		mkdir -p $LOG_DIR
		mkdir -p $JOB_DIR

		local jid="${RANDOM}_N4" # generate random number as job ID, alternatively, use: $$
		local job_list=$JOB_DIR/$USER.$jid.$(date +%y%m%d%H%M%S).txt
		rm -f $job_list
	fi

	local id
	for id in $(cat $target_list); do
		local target_id=$id
		# N4 parameter
		N4_parameter=""
		if [[ $mask_flag -eq 1 ]]; then
			# if [[ -z $mask_dir ]]; then
			# 	mask_dir=$affine_mask_dir
			# fi
			N4_parameter="$N4_parameter -x $mask_dir/$id$mask_suffix.nii.gz"
		fi
		N4_parameter="$N4_parameter -i $input_dir/$id.nii.gz -o $result_dir/$id.nii.gz -r 1 -v"
		# local/cluster process
		if [[ "$exe_mode" == "local" ]]; then
			echo "[local preprocessing] N4BiasFieldCorrection for $id ..."
			N4BiasFieldCorrection $N4_parameter
		elif [[ "$exe_mode" == "cluster" ]]; then
			echo "[cluster preprocessing] N4BiasFieldCorrection for $id ..."
			local job_name=$jid.$target_id
			local pbs_file=$PBS_DIR/$job_name.pbs
			local log_file=$LOG_DIR/$job_name.log
			# clean up files if pre-exist
			rm -f $pbs_file
			rm -f $log_file
			# add pbs header info
			pbsBoilerPlate -n $job_name -m $MEM -w $WALLTIME -j -O $log_file -f $pbs_file # -O /dev/null
			echo "N4BiasFieldCorrection $N4_parameter" >> $pbs_file
			qsub $pbs_file
			echo "1,qsub $pbs_file" >> $job_list
		fi
	done
}


# ---------------------------------
#  function: slurmBoilerPlate
# ---------------------------------
function slurmBoilerPlate(){
	local function_name=${FUNCNAME[0]}
	usage() {
		echo -e """[Usage] $function_name -a \$account -m \$mem -t \$time -n \$job_name  -f \$sbatch_file -o \$log_file		 """
		return 1
	}
	# -o /dev/null

	local OPTIND
	local options
	# print a seperate line
	echo ""

	while getopts ":a:m:t:n:f:o:h" options; do
		case $options in
			a ) echo "Account name:         $OPTARG"
				local account=$OPTARG;;
			m ) echo "Memory:               $OPTARG"
				local mem_per_cpu=$OPTARG;;
			t ) echo "Wall time:            $OPTARG"
				local time=$OPTARG;;
			n ) echo "Job name:             $OPTARG"
				local job_name=$OPTARG;;
			f ) echo "Sbatch file:          $OPTARG"
				local sbatch_file=$OPTARG;;
			o ) echo "Log file:             $OPTARG"
				local log_file=$OPTARG;;
			h ) usage; return 1;;
			\?) echo "Unknown option"
			 	usage; return 1;;
			: ) usage; return 1;;
		esac
	done

	if [[ $OPTIND -eq 1 ]]; then
		echo "[$function_name] no option specified"
		usage; return 1
	fi 

	echo "[$function_name] generating sbatch files $sbatch_file... "
	echo "#!/bin/bash" > $sbatch_file
	echo "#SBATCH --account=$account" >> $sbatch_file
	echo "#SBATCH --time=$time"       >> $sbatch_file
	echo "#SBATCH --mem-per-cpu=$mem" >> $sbatch_file
	echo "#SBATCH --job-name=$name"   >> $sbatch_file
	echo "#SBATCH --output=$log_file" >> $sbatch_file
}


# ---------------------------------
#  function: slurm_mas_masking
# ---------------------------------
function slurm_mas_masking(){
  local function_name=${FUNCNAME[0]}
  usage() {
    echo """[Usage] $function_name \$target_dir \$atlas_dir \$target_id \$atlas_id \$result_dir \$job_dir"""
    return 1
  }

  if [[ $# -lt 4 ]]; then
    usage; return 1;
  fi
    
  local target_dir=$1
  local atlas_dir=$2
  local target_id=$3
  local atlas_id=$4
  
  job_name="${target_id}-${atlas_id}_label_prop_affine"
  sbatch_file="${job_dir}/sbatch/${job_name}.sh"
  log_file="${job_dir}/logs/${job_name}.log"

  #%% jobs
  slurmBoilerPlate -a $account\
                   -m $mem \
                   -t $time \
                   -n $job_name  \
                   -f $sbatch_file \
                   -o $log_file
                    # -o /dev/null

  mas_cmd=$(echo mas_masking \
    -T $target_dir \
    -t $target_id \
    -A $atlas_dir \
    -a $atlas_id \
    -r $result_dir )

    
  # %%
  echo $mas_cmd >> $sbatch_file

  return 0
}

# ---------------------------------
#  function: slurm_mas_masking
# ---------------------------------
function slurm_mas_masking_atlas_array(){
  local function_name=${FUNCNAME[0]}
  usage() {
    echo """[Usage] $function_name \$target_dir \$atlas_dir \$target_id \$job_dir"""
    return 1
  }

  if [[ $# -lt 4 ]]; then
    usage; return 1;
  fi
    
  local target_dir=$1
  local atlas_dir=$2
  local target_id=$3
  local atlas_id=$4
  
  job_name="${target_id}-${atlas_id}_label_prop_affine"
  sbatch_file="${job_dir}/sbatch/${job_name}.sh"
  log_file="${job_dir}/logs/${job_name}.log"

  #%% jobs
  slurmBoilerPlate -a $account\
                   -m $mem \
                   -t $time \
                   -n $job_name  \
                   -f $sbatch_file \
                   -o $log_file
                    # -o /dev/null

  mas_cmd=$(echo mas_masking \
    -T $target_dir \
    -t $target_id \
    -A $atlas_dir \
    -a $atlas_id \
    -r $result_dir )

    
  # %%
  echo $mas_cmd >> $sbatch_file

  return 0
}