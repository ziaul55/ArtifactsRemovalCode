function im_res = non_local_means_filtering(im,opts)
%NON_LOCAL_MEANS_FILTERING filtration using non-local means filtering
% INFO: does not support gpuArrays
% im - jpg image (uint8)
% opts - structure with following parameters
% - DoS - degree of smoothing multiplier of the standard deviation calculated from roi
im= im2double(im);
im = rgb2lab(im);

% Extract a homogeneous L*a*b patch from the noisy background to compute the noise standard deviation.
roi = [210,24,52,41];
patch = imcrop(im,roi);

patchSq = patch.^2;
edist = sqrt(sum(patchSq,3));
patchSigma = sqrt(var(edist(:)));

% Set the 'DegreeOfSmoothing' value to be higher than the standard deviation of the patch.
% Filter the noisy L*a*b* image using non-local means filtering.

DoS = opts.DoS*patchSigma;
im_res = imnlmfilt(im,'DegreeOfSmoothing',DoS);
im_res = lab2rgb(im_res,'Out','double');
im_res = im2uint8(im_res);
end

