function im_res = wave_filtering(im, opts)
%WAVE_FILTERING function to perform filtering with wave filter
% im - jpg image (uint8)
% opts - structure with following parameters:
% wname - wavelet type
% thr_type -  {default}   - use ddencmp function - default values for denoising or compression
%             {penalized} - Estimate the noise standard deviation from the detail coefficients at given level.
% alpha - penalization parameter
% level - decomposition level
% keepapp - Threshold approximation setting, If keepapp = 1, the approximation coefficients are not thresholded.
% returns - im_res - filtred image (uint8)

im = im2double(im);         
[n, m, d] = size(im);
im_res = zeros(n, m, d, 'double');

for i=1:d
    im_res(:,:,i) = filt_wave(im(:,:,i),opts);
end

im_res = im2uint8(im_res);
end

