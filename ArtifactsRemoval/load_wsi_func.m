function mbim = load_wsi_func(filepath, output, blocksize, parallel, filt_size, sigma, res_path, gpu)
%LOAD_WSI_FUNC Function to read and process a WSI image
% filepath - WSI localization
% output - path for folder with binary files created during block
% processing
% blocksize - size of a block
% filt_size - size of a filter kernel
% sigma - std of a gaussian filter
% res_path - path for the result image
% gpu - use gpu or not
% returns: mbim - processed blocked image

% load blocked image
bim = blockedImage(filepath);


% count tresholds for each color channel (otsu method)
layer=gather(bim,"Level",3);
params = zeros(3,1, 'double');

for i=1:3
    [gmag, ~] = imgradient(layer(:,:,i), 'central');
    gmag_grayscale = mat2gray(gmag);
    params(i)=graythresh(gmag_grayscale);
end

% remove artifacts (block processing)

benh= apply(bim,...
    @(bs)method2_WSI(bs.Data, params, sigma, filt_size,gpu),...
    "BorderSize", [filt_size filt_size],"Level",1, "UseParallel",parallel,"OutputLocation",output,"BlockSize",blocksize);


% create layers with lower resolution
 mbim = makeMultiLevel2D(benh,"Scales",[1 0.25 0.125 0.06125]);

% save image
 wadapter = images.blocked.TIFF; 
 write(mbim, res_path, "Adapter", wadapter);

end

