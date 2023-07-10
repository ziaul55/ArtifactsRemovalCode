function im_res = gaussian_filtering(im,opts)
% Function to perform gaussian filtering
% im - jpg image (uint8)
% opts - structure with following parameters
% - Size - size of the filter
% - Sigma - std of the filter
% returns im_res the image after filtering

im = im2double(im);
filter_mask=gaussian_mask(opts.Sigma, opts.Size);
im_res = imfilter(im, ...
    filter_mask, 'symmetric', 'conv');
im_res = im2double(im_res);

end

