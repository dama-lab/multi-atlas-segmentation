% Matlab function to batch-reorient .nii images
% Require the Matlab NIfTI toolbox available at:
%     (https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image)
% @author: MA, Da, da_ma@sfu.ca, d.ma.11@ucl.ac.uk

function reorientNii(input,output_folder)

[~,input_name,input_ext]=fileparts(input);
% load test image
A=load_nii(input);
% display test image
view_nii(A);
% reorient test image
A=rri_orient(A);

% M=[A.hdr.dime.pixdim(2) A.hdr.dime.pixdim(3) A.hdr.dime.pixdim(4)];
% A=make_nii(A.img,M);

if ~exist(output_folder,'dir') % 7=folder
    mkdir(output_folder);
end
% save reoriented image
output= strcat(output_folder,'/',input_name,input_ext);
save_nii(A,output);
close(gcf);