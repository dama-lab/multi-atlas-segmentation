# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.08.29

# usage: ./leave_one_out_dice_STAPLE.sh $1
# $1: atlas (in_vivo ex_vivo)

ROOT_DIR=$(pwd)
# echo "Bash version ${BASH_VERSION}..."
ATLAS=$(basename $1)
LABEL_NUMBER=80

echo -e "STAPLE\c" >> "$1/Dice_Score/Dice_Score_STAPLE.csv"
for ((m=1;m<=$LABEL_NUMBER;m+=1)) 
do
  echo -e ",$m\c" >> "$1/Dice_Score/Dice_Score_STAPLE.csv"
done
echo -e "\n\c" >> "$1/Dice_Score/Dice_Score_STAPLE.csv"

# begin dice score calculation
for H in `ls $1/template/`
do
  TEST_NAME=`echo "$H" | cut -d'.' -f1`
  echo "******************************************"
  echo "* leave one out (STAPLE) Dice score *"
  # echo "******************************************"
  # Exporting Dice score for template image
  # seg_stats $1/label/$H -D "\"label/${TEST_NAME}_${ATLAS}_label_STAPLE.nii.gz\"" "\"$1/Dice_Score/temp/${TEST_NAME}_${ATLAS}_label_STAPLE.csv\""
  echo -e $TEST_NAME",\c" >> "$1/Dice_Score/Dice_Score_STAPLE.csv"
  cat "$1/Dice_Score/temp/${TEST_NAME}_${ATLAS}_label_STAPLE.csv" >> "$1/Dice_Score/Dice_Score_STAPLE.csv"
  echo -e "\n\c" >> "$1/Dice_Score/Dice_Score_STAPLE.csv"
  
done