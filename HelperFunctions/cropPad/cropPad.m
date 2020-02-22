function vol = cropPad(vol,padNum)
%% crop the zero padding around multi-dimensional volume
% Author: Da Ma (da_ma@sfu.ca)
% [Yet to be implemented]:
% padNum: Number of voxels to pad around the cropped images

%%
% get volume size
volSize = size(vol);
% get number of dimension
numDim = length(volSize);

%% Initialize cropping parameter
cropParam = nan(numDim,2);

for dim = 1:numDim
    %% find the remainign dimension number
    dimRemain = setdiff(1:numDim,dim);
    %% find the min/max index of non-zero value in vol for this dimension 
    numEle = 1; % only need to find the index of the 1st find non-zero value
    cropParam(dim,1) = find(max((vol>0),[],dimRemain),numEle); % min
    cropParam(dim,2) = find(max((vol>0),[],dimRemain),numEle, 'last'); % max
end

%% cropping the vol in each dim
for dim = 1:numDim
    % crop current dimension
    vol = vol(cropParam(dim,1):cropParam(dim,2),:,:);
    % shift the 1st dimension to the last, to prepare croping the next dimension
    vol = shiftdim(vol,1);
end