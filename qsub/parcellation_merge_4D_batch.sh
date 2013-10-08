# merge 4D-labels for images in a folder
# $1: folder contains enquiry images
# $2: atlas folder "in_vivo" or "ex_vivo"

for G in `ls $1`
do
  parcellation_merge_4D.sh $1/$G $2
done