function tab_res = calculate_stats(tab)
%CALCULATE_STATS Function to calculate statistics
% tab - table with raw data
tab_res = grpstats(tab,["Q","Sigma","Size"],["mean", "std", "var","meanci"],"DataVars",["psnr","ssim","ssim_jpg","psnr_jpg"]);
end

