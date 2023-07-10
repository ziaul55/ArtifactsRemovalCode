function im_res = imbilateral_filtering(im, opts)
%IMBILATERAL_FILTERING Bilateral filtering of images with Gaussian kernels
% INFO: does not support gpuArrays
% im - jpg image (uint8)
% opts - structure with following parameters
% - DoS - degree of smoothing multiplier
% - Sigma - Standard deviation of spatial Gaussian smoothing kernel (default = 1)
% returns im_res - filtred image

imLAB = rgb2lab(im);

%Set the degree of smoothing to be larger than the variance of the noise.
patch = imcrop(imLAB,[34,71,60,55]);
patchSq = patch.^2;
edist = sqrt(sum(patchSq,3));
patchVar = std2(edist).^2;

DoS = opts.DoS*patchVar;
smoothedLAB = imbilatfilt(imLAB,DoS, opts.Sigma);
im_res = lab2rgb(smoothedLAB,"Out","double");

im_res = im2uint8(im_res);

end

