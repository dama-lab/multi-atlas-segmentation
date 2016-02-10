# Structural Parcellation shell script (SGE)
# Author: Ma Da (d.ma.11@ucl.ac.uk)
# Version 0.8_2013.10.19 to be modified ...
#!/bin/bash
# echo "Bash version ${BASH_VERSION}..."
# $1: folder include all the images to be masked
# $2: atlas folder
# $3: parcellation parameter file (if exist)

#!/bin/bash
DILATE=4
ATLAS=$(basename $2)

for G in `ls $1`
do
  TEST_NAME=`echo "$G" | cut -d'.' -f1`
  NAME=`echo "$G" | cut -d'.' -f1`
  mask.sh $1/$G $2 $3
done