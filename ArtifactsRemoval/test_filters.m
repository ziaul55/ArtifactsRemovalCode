% Script to test different filtration types

im = imread("jpg_conv.jpg");
gpu = true;
%% 1. EPA

opts1.Sigma = 1.4;
opts1.Size = 3;
opts1.CutPoint = [1 1];

im_1 = process_image(im, opts1, "EPA",gpu );
imshowpair(im, im_1, "montage");

%% 2. EPA_ID_gauss

opts2.Sigma = 1.4;
opts2.Size = 3;
opts2.CutPoint = [1 1];

im_2 = process_image(im, opts2, "EPA_ID_gauss",gpu);
imshowpair(im, im_2, "montage");

%% 3. EPA_ID_avg

opts3.Size = 3;
opts3.CutPoint = [1 1];

im_3 = process_image(im, opts3, "EPA_ID_avg",gpu);
imshowpair(im, im_3, "montage");

%% 4. EPA_ID_guided - does not support gpuArrays

opts4.CutPoint = [1 1];
opts4.DoS = 0.0004;
opts4.NeighSize = 3;


im_4 = process_image(im, opts4, "EPA_ID_guided",false);
imshowpair(im, im_4, "montage");

%% 5. EPA_ID_imdiffuse  - does not support gpuArrays

opts5.ConductionMethod = "exponential";
opts5.Connectivity = "minimal";
opts5.CutPoint = [1 1];
im_5 = process_image(im, opts5, "EPA_ID_imdiffuse", false);
imshowpair(im, im_5, "montage");


%% 6. EPA_ID_median

opts6.Size = 3;
opts6.CutPoint = [1 1];

im_6 = process_image(im, opts6, "EPA_ID_median",gpu);
imshowpair(im, im_6, "montage");

%% 7. non_local_means_filtering

opts7.DoS = 1.7;
opts7.CutPoint = [1 1];
im_7 = process_image(im, opts7, "EPA_ID_non_local_means",gpu);
imshowpair(im, im_7, "montage");

%% 8. EPA_ID_wave

opts8.wname ='db3';   
opts8.thr_type = 'penalized';
opts8.alpha = 5;            
opts8.level = 2;             
opts8.keepapp = 1; 
opts8.CutPoint = [1 1];

im_8 = process_image(im, opts8, "EPA_ID_wave",gpu);
imshowpair(im, im_8, "montage");

%% 9. EPA_ID_wiener

opts9.Size = 3;
opts9.CutPoint = [1 1];

im_9 = process_image(im, opts9, "EPA_ID_wiener",gpu);
imshowpair(im, im_9, "montage");

%% 10. EPA_ID_W 

opts10.Size = 3;
opts10.Sigma = 1.4;
opts10.CutPoint = [1 1];

im_10 = process_image(im, opts10, "EPA_ID_W",gpu);
imshowpair(im, im_10, "montage");

%% 11. avg_filering 
opts11.Size = 3;

im_11 = process_image(im, opts11, "avg_filtering",gpu);
imshowpair(im, im_11, "montage");

%% 12. gaussian_filtering 

opts12.Size = 3;
opts12.Sigma = 1.4;

im_12 = process_image(im, opts12, "gaussian_filtering",gpu);
imshowpair(im, im_12, "montage");

%% 13. guided_filtering - does not support gpuArrays
opts13.DoS = 0.0004;
opts13.NeighSize = 3;

im_13 = process_image(im, opts13, "guided_filtering",false);
imshowpair(im, im_13, "montage");

%% 14. imbilateral_filtering - does not support gpuArrays
opts14.DoS =1.1;
opts14.Sigma = 3;
im_14 = process_image(im, opts14, "imbilateral_filtering",false);
imshowpair(im, im_14, "montage");

%% 15. Anisotropic diffusion filtering (imdiffusse_filtering) - does not support gpuArrays
opts15.ConductionMethod = "exponential";
opts15.Connectivity = "minimal";
im_15 = process_image(im, opts15, "imdiffuse_filtering",false);
imshowpair(im, im_15, "montage");

%% 16. median_filtering 

opts16.Size = 5;

im_16 = process_image(im, opts16, "median_filtering",gpu);
imshowpair(im, im_16, "montage");

%% 17. non_local_means_filtering - does not support gpuArrays

opts17.DoS = 1.7;

im_17 = process_image(im, opts17, "non_local_means_filtering",false);
imshowpair(im, im_17, "montage");

%% 18. wave_filtering

opts18.wname ='db3';   
opts18.thr_type = 'penalized';
opts18.alpha = 5;            
opts18.level = 2;             
opts18.keepapp = 1; 

im_18 = process_image(im, opts18, "wave_filtering",gpu);
imshowpair(im, im_18, "montage");

%% 19. wiener_filtering

opts19.Size = 3;

im_19 = process_image(im, opts19, "wiener_filtering",gpu);
imshowpair(im, im_19, "montage");

%% 20 a) MMWF - gpuArrays - time consuming

opts20a.Size = 3;
opts20a.Filter = "MMWF";

im_20a = process_image(im, opts20a, "MMWF_2D_filtering",false);

%MMWF
imshowpair(im, im_20a, "montage");

%% 20 b) MMWF* - gpuArrays - time consuming

opts20b.Size = 3;
opts20b.Filter = "MMWF*";

im_20b = process_image(im, opts20b, "MMWF_2D_filtering",false);
imshowpair(im, im_20b, "montage");