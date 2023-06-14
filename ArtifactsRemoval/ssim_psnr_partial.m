function [psnr_vals,ssim_vals] = ssim_psnr_partial(im_compressed,im_after_removal)
% jpg vs after removal, 
psnr_vals=calculate_partial_MSE(im_compressed, im_after_removal);
[ssimVal, ~]=ssim(im_compressed, im_after_removal,"DataFormat","SSC");
ssim_vals=mean(ssimVal,"all");
end

