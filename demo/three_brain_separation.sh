#!/bin/bash

##################
# multi brain seperation
##################

source MultiAtlasSegmentation

function convert_dcm_to_nifti_batch(){
	local function_name=${FUNCNAME[0]}
	local line
	for line in $(cat $targetlist_raw); do
		local id=$(echo $line | cut -d',' -f1)
		local input_dir=$(echo $line | cut -d',' -f2)
		MIAL_convert_to_nifti 
		# dcm2niix_afni -9 -f $id -t -o $dcm_nii_dir -v 1 -z i $input_dir
		# mv $input_dir/$id.nii.gz $dcm_nii_dir
	done
}

function multi_brain_seperation(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 3 ]]; then
		echo "Usage: $function_name [target_dir] [target_id] [result_dir] [(Optional) brain_no]"
		return 1
	fi

	local target_dir=$1
	local target_id=$2
	local result_dir=$3
	local brain_no
	if [[ ! -z $4 ]]; then
		brain_no=$4
	else
		# default number of brain = 3
		brain_no=3
	fi

	echo "target_dir=$target_dir"
	echo "target_id=$target_id"
	echo "result_dir=$result_dir"

	local thr=5000
	local ero=2
	local dil=4
	local ero2=2
	local tmp_dir=$result_dir/tmp_${RANDOM}
	mkdir -p $tmp_dir
	# create multi-brain mask
	seg_maths $target_dir/$target_id -thr $thr -bin -ero $ero -dil $dil -fill -ero $ero2 $tmp_dir/${target_id}_multimask_1.nii.gz
	local i=1
	while [[ i -le $brain_no ]]; do
		echo "extract ${i}th brain"
		# extract ${i}th mask out
		seg_maths $tmp_dir/${target_id}_multimask_$i.nii.gz -lconcomp $tmp_dir/${target_id}_mask_$i.nii.gz
		# using mask
		seg_maths $tmp_dir/${target_id}_mask_$i.nii.gz -dil 1 -mul $target_dir/$target_id $result_dir/${target_id}_${i}.nii.gz
		# substract ${i}th extracted mask
		if [[ i -lt $brain_no ]]; then
			# echo "substract ${i}th extracted mask (-sub)"
			seg_maths $tmp_dir/${target_id}_multimask_$i.nii.gz -sub $tmp_dir/${target_id}_mask_$i.nii.gz $tmp_dir/${target_id}_multimask_$(( i + 1 )).nii.gz
		fi
		i=$(( $i + 1 ))
	done
	rm -rf $tmp_dir
}

function multi_brain_seperation_batch(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 3 ]]; then
		echo "Usage: $function_name [target_dir] [targetlist] [result_dir]"
		return 1
	fi

	local target_dir=$1
	local targetlist=$2
	local result_dir=$3

	# local thr=5000
	# local ero=2
	# local dil=6
	# local ero2=4
	# local tmp_dir=$result_dir/tmp_${RANDOM}
	# mkdir -p $tmp_dir
	# brain_no=3

	for target_id in $(cat $targetlist); do
		multi_brain_seperation $target_dir $target_id $result_dir # $brain_no
		# seg_maths $target_dir/$target_id -thr $thr -bin -ero $ero -dil $dil -fill -ero $ero2 $tmp_dir/${target_id}_mask_multi.nii.gz
	done
}

function fix_header_info(){
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

function reorder_brain(){
	# not working properly
    local function_name=${FUNCNAME[0]}
    if [[ $# -lt 3 ]];then
	    echo "Usage: $function_name [input_nii] [output_nii] [out_orientation]"
	    return 1
    fi
    
    local input_nii=$1
    local output_nii=$2
    local orient_out=$3 #RAS

    local orient_in=$(getOrientation $input_nii)
    ReorderImage $input_nii $orient_in $output_nii $orient_out
    fix_header_info $output_nii $orient_out $output_nii
}


function reorient_brain(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 4 ]]; then
		echo "Usage: $function_name [target_dir] [target_id] [location (L/R/S)] [result_dir]"
		return 1
	fi

	local target_dir=$1
	local target_id=$2
	local location=$3
	local result_dir=$4

	local out_orientation=RAS

	if [[ "$location" = "S" ]]; then
		orientation=RSA
		# fix_header_info $target_dir/$target_id RSA $result_dir/$target_id.nii.gz
	elif [[ "$location" = "R" ]]; then
		orientation=ILA
		# fix_header_info $target_dir/$target_id IRA $result_dir/$target_id.nii.gz
	elif [[ "$location" = "L" ]]; then
		orientation=SRA
	fi
	# local 
	target_file=$(ls $target_dir/${target_id}* | cut -d' ' -f1)

	fix_header_info $target_file $orientation $result_dir/$target_id.nii.gz

	# local tmp_dir=$result_dir/tmp_${RANDOM}
	# mkdir -p $tmp_dir
	# fix_header_info $target_file $orientation $tmp_dir/$target_id.img "analyze"
	# reorder_brain $tmp_dir/$target_id.img $tmp_dir/${target_id}.reorder.img $out_orientation
	# fix_header_info $tmp_dir/${target_id}.reorder.img $out_orientation $result_dir/$target_id.nii.gz
	# rm -rf $tmp_dir

}

function reorient_brain_batch_3brain(){
	local function_name=${FUNCNAME[0]}
	if [[ $# -lt 3 ]]; then
		echo "Usage: $function_name [target_dir] [scan_list] [result_dir]"
		return 1
	fi

	local target_dir=$1
	local scan_list=$2
	local result_dir=$3

	echo "target_dir=$target_dir"
	echo "scan_list=$scan_list"
	echo "result_dir=$result_dir"

	local scan_id
	local target_id

	for scan_id in $(cat $scan_list); do
		for location in L R S; do
			target_id=${scan_id}_$location
			if [[ -e $target_dir/$target_id.nii.gz ]]; then
				echo "............... reorienting: $target_id ..............."
				reorient_brain $target_dir $target_id $location $result_dir
			fi
		done
	done
}

function extract_label(){
	local function_name=$[FUNCNAME[0]]
	if [[ $# -lt 4 ]]; then
		echo "Usage: $function_name [target_dir] [target_id] [label] [result_dir]"
		return 1
	fi

	local target_dir=$1
	local target_list=$2
	local label=$3
	local result_dir=$4

	seg_maths $target_dir/$target_id.nii.gz -thr $(($label-0.5)) -uthr $(($label+0.5)) $result_dir/$target_id.nii.gz
}

function masking_batch_nii(){
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
		for atlas_id in $(cat $atlas_dir/$AtlasListFileName); do
			# cloud process need to run on rcg-queen
			# local target_result_dir=$result_dir/$target_id
			# mkdir -p $target_result_dir
			mas_masking -T $target_dir -t $target_id -A $atlas_dir -a $atlas_id -r $result_dir
		done
	done
}