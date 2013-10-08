# start from splash path:
# usage: single_atlas_dice.sh $1 $2
# $1 Test atlas folder
# $2 Source atlas folder
ROOT_DIR=$(pwd)
# echo "Bash version ${BASH_VERSION}"
ATLAS=$(basename $2)
export QSUB_CMD="qsub -l h_rt=1:00:00 -l h_vmem=9.9G -l tmem=9.9G -l s_stack=128M -j y -S /bin/sh -b y -cwd -V -o job_output -e job_error"

if [ ! -d "Dice_Score/temp" ]
  then mkdir -p "Dice_Score/temp"
fi

for H in `ls $1/template/`
do
  TEST_IMAGE=`echo "$H" | cut -d'.' -f1`
  echo -e ${TEST_IMAGE}"," >> "Dice_Score/Dice_Score_single.csv"
  for G in `ls $2/template/`
  do
	ATLAS_IMAGE=`echo "$G" | cut -d'.' -f1`
	echo -e ${ATLAS_IMAGE}",\c" >> "Dice_Score/Dice_Score_single.csv"
	cat "Dice_Score/temp/${TEST_IMAGE}_label_${ATLAS_IMAGE}.csv" >> "Dice_Score/Dice_Score_single.csv"
	echo -e "\n\c" >> "Dice_Score/Dice_Score_single.csv"
  done
  echo -e "\n\c" >> "Dice_Score/Dice_Score_single.csv"
done


############# old script ###########
# echo -e "A0_label_A0_flip,\c" >> "dice_score.csv"
# seg_stats ../../in_vivo_double/label/A0.nii.gz -D in_vivo_double/A0_label_A0_flip.nii.gz "dice_score.csv"
# echo -e "\n\c" >> "dice_score.csv"