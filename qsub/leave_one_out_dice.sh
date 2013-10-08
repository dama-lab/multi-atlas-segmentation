# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.08.29

# usage: ./leave_one_out_dice.sh $1 $2 $3
# $1: atlas (in_vivo ex_vivo)
# $2: STEPS parameter k (kernel size in terms of voxel number)
# $3: STEPS parameter n (number of top ranked local atlas to select for label fusion)
ROOT_DIR=$(pwd)
# echo "Bash version ${BASH_VERSION}..."
ATLAS=$(basename $1)
LABEL_NUMBER=80

# Set STEPS parameters
if [[ ! -z $2 ]] && [[ ! -z $3 ]]; then  # if STEPS parameter is set (-z: zero = not set), so ! -z = set
  export k=$2
  export n=$3
else # if [[ -z "${STEPS_PARAMETER}" ]] set default STEPS parameter to: "4 6 "
  export k=4
  export n=6
fi
export STEPS_PARAMETER="${k} ${n} " 

echo -e "k=${k}+n=${n}\c" >> "$1/Dice_Score/Dice_Score_STEPS_${k}_${n}.csv"
for ((m=1;m<=$LABEL_NUMBER;m+=1)) 
do
  echo -e ",$m\c" >> "$1/Dice_Score/Dice_Score_STEPS_${k}_${n}.csv"
done
echo -e "\n\c" >> "$1/Dice_Score/Dice_Score_STEPS_${k}_${n}.csv"

# begin dice score calculation
for H in `ls $1/template/`
do
  TEST_NAME=`echo "$H" | cut -d'.' -f1`
  echo "******************************************"
  echo "* leave one out (STEPS $k $n) Dice score *"
  # echo "******************************************"
  # Exporting Dice score for template image
  echo -e $TEST_NAME",\c" >> "$1/Dice_Score/Dice_Score_STEPS_${k}_${n}.csv"
  cat "$1/Dice_Score/temp/${TEST_NAME}_STEPS_${k}_${n}.csv" >> "$1/Dice_Score/Dice_Score_STEPS_${k}_${n}.csv"
  echo -e "\n\c" >> "$1/Dice_Score/Dice_Score_STEPS_${k}_${n}.csv"
  
done