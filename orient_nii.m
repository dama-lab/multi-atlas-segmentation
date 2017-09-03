% Matlab function to batch-reorient .nii images using the Matlab NIfTI
% toolbox.
% @author: MA, Da, d.ma.11@ucl.ac.uk
%       TIG@CMIC & Phenotyping@CABI, UCL, London, UK

function orient_nii(input,output_folder)

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