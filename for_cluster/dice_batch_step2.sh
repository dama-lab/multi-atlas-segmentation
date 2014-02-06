# Brain extraction shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.08.29

# usage: ./dice_batch.sh $1 $2 $3 $4 $5
# $1: destination atlas folder to be tested (only use label subfolder)
# $2: source atlas folder containing multiple manual labels
# $3: folder containing the parcellated structures
# $4: STEPS parameter k (kernel size in terms of voxel number)
# $5: STEPS parameter n (number of top ranked local atlas to select for label fusion)
ROOT_DIR=$(pwd)
# echo "Bash version ${BASH_VERSION}..."
ATLAS=$(basename $2)
LABEL_NUMBER=40

if [ ! -d Dice_Score/temp ]
  then mkdir -p Dice_Score/temp
fi
# Set STEPS parameters
if [[ ! -z $5 ]] && [[ ! -z $4 ]]; then  # if STEPS parameter is set (-z: zero = not set), so ! -z = set
  export k=$4
  export n=$5
else # if [[ -z "${STEPS_PARAMETER}" ]] set default STEPS parameter to: "3 8 "
  export k=3
  export n=8
fi
export STEPS_PARAMETER="${k} ${n} " 

# Title line
echo -e "k=${k}+n=${n}\c" >> "Dice_Score/${ATLAS}_Dice_Score_STEPS_${k}_${n}.csv"
for ((m=1;m<=$LABEL_NUMBER;m+=1)) 
do
  echo -e ",$m\c" >> "Dice_Score/${ATLAS}_Dice_Score_STEPS_${k}_${n}.csv"
done
echo -e "\n\c" >> "Dice_Score/${ATLAS}_Dice_Score_STEPS_${k}_${n}.csv"

# begin dice score calculation
for H in `ls $1/template/`
do
  TEST_IMAGE=`echo "$H" | cut -d'.' -f1`
  echo "******************************************"
  echo "* Dice score OF ${TEST_IMAGE} step 2 (STEPS $k $n) *"
  # echo "******************************************"
  # Step 2: Exporting Dice score for template image
  echo -e "${TEST_IMAGE},\c" >> "Dice_Score/${ATLAS}_Dice_Score_STEPS_${k}_${n}.csv"
  cat "Dice_Score/temp/${TEST_IMAGE}_${ATLAS}_label_STEPS_${k}_${n}.csv" >> "Dice_Score/${ATLAS}_Dice_Score_STEPS_${k}_${n}.csv"
  echo -e "\n\c" >> "Dice_Score/${ATLAS}_Dice_Score_STEPS_${k}_${n}.csv"
done