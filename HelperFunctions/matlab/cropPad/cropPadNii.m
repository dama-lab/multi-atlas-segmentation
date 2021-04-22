function cropPadNii(niiIn,niiOut,compressFlag,normalizeFlag,padNum)
%% crop the zero padding around nifti file
% Author: Da Ma (da_ma@sfu.ca)
% compressFlag: whether to compress the output nifti file (Default: False)
% normalizeFlag: whether/how to normalize the input volume
%    0 (default): donot normalize
%    1 : normalize to [0,1]
% [Yet to be implemented]:
% padNum: Number of voxels to pad around the cropped images
%%

% By default, don't compress .nii file to .nii.gz
if ~exist('compressFlag','var'); compressFlag=false;end
% By default, compress to [0,1]
if ~exist('normalizeFlag','var'); normalizeFlag=0;end

%% Read input nifti
disp('loading nifti file ...')
% read nifti volume
vol = niftiread(niiIn);
% % read nifti head
disp('read nifti header ...')
niiHead = niftiinfo(niiIn);
%% crop zero pad
disp('cropping nifti volume ...')
vol = cropPad(vol);
% [Yet to be implemented]:
% padNum: Number of voxels to pad around the cropped images%% normalze
if normalizeFlag == 1
    vol = mat2gray(vol);
    vol = single(vol);
end

%% update header dimension
niiHead.ImageSize = size(vol);
niiHead.raw.dim(2:4) = size(vol);

%% save nifti
disp('saving nifti file ...')
% determine if need to save as a '.nii.gz' compression file
[niiPath,niiName,niiExt] = fileparts(niiOut);
[~,~,internalExt] = fileparts(niiName);
if internalExt == ".nii" ||niiExt == ".gz"
    compressFlag = 1; % = true
end
savePath = fullfile(niiPath,niiName);
%% save nii
niftiwrite(vol,savePath,niiHead,'Compressed',compressFlag);

