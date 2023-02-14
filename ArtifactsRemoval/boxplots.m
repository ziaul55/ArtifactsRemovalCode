%% Script to create boxplots
folderpath='..\Results\ResultsAllMethods\Tables\Raw\Q';
Q='90';
blur_avg=readtable(strcat(folderpath,Q,'\blur\Avg\3_avg.csv'));
tab1_avg=readtable(strcat(folderpath,Q,'\method_1\Avg\3_avg.csv'));
tab2_avg=readtable(strcat(folderpath,Q,'\method_2\Avg\3_avg.csv'));
tab3_avg=readtable(strcat(folderpath,Q,'\method_3\Avg\3_avg.csv'));

blur_gauss=readtable(strcat(folderpath,Q,'\blur\Gauss\sigma_0.7f_size3_gauss.csv'));
tab1_gauss=readtable(strcat(folderpath,Q,'\method_1\Gauss\sigma_0.7f_size3_gauss.csv'));
tab2_gauss=readtable(strcat(folderpath,Q,'\method_2\Gauss\sigma_0.7f_size3_gauss.csv'));
tab3_gauss=readtable(strcat(folderpath,Q,'\method_3\Gauss\sigma_0.7f_size3_gauss.csv'));

quality="Q10";
names=["blur (avg)" "method 1 (avg)" "method 2 (avg)" "method 3 (avg)" "blur (gauss)" "method 1 (gauss)" "method 2 (gauss)" "method 3 (gauss)"];
filters=["gauss" "avg"];
title=["SSIM" "PSNR" "NIQE" "BRISQUE"];

niqe_plot_avg=boxplot([blur_avg.delta_niqe tab1_avg.delta_niqe tab2_avg.delta_niqe tab3_avg.delta_niqe blur_gauss.delta_niqe tab1_gauss.delta_niqe tab2_gauss.delta_niqe tab3_gauss.delta_niqe],'Notch','on', ...
    'Labels',names);
ssim_plot_avg=boxplot([blur_avg.delta_SSIM tab1_avg.delta_SSIM tab2_avg.delta_SSIM tab3_avg.delta_SSIM blur_gauss.delta_SSIM tab1_gauss.delta_SSIM tab2_gauss.delta_SSIM tab3_gauss.delta_SSIM],'Notch','on', ...
    'Labels',names);
psnr_plot_avg=boxplot([blur_avg.delta_PSNR tab1_avg.delta_PSNR tab2_avg.delta_PSNR tab3_avg.delta_PSNR blur_gauss.delta_PSNR tab1_gauss.delta_PSNR tab2_gauss.delta_PSNR tab3_gauss.delta_PSNR],'Notch','on', ...
    'Labels',names);

