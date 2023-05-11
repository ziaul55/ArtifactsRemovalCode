im_jpg= imread('jpg_conv.jpg');
opts.wname ='db4';
opts.thr_type = 'default';
opts.alpha = 2;
opts.level =3;
opts.keepapp=0;


%Image processing parameters
opts.proc_type = 'local';%local or global processing
opts.back_type = 'none';%background correction method {'none','IPF','RB','OTSU'}
opts.filt_type = 'none';%filltering method {'none','MEDF','MMWF','WAVE'}
opts.poly_deg = 4;      %IPF - degree of fitting polynomial
opts.ball_size = 20;    %RB - size of rolling ball element
opts.mask = 3;          %MEDF,MMWF - moving window size
opts.win_num = 5;       %2DMF - no. of overlapping fragments
opts.win_lap = 10;      %2DMF - overlap [%]
opts.alpha = 5;         %WAVE - penalization parameter
opts.wname = 'db3';     %WAVE - wavelet type
opts.level = 2;         %WAVE - decomposition level

opts.wname ='db3';           % wavelet type
opts.thr_type = 'penalized'; % {default} - use ddencmp function - default values for denoising or compression
% {penalized} - Estimate the noise standard deviation from the detail coefficients at given level.
opts.alpha = 5;              % penalization parameter
opts.level = 2;              % decomposition level
opts.keepapp = 1;            % Threshold approximation setting, If keepapp = 1, the approximation coefficients are not thresholded.


im_jpg=im2double(im_jpg);
data_filt(:,:,1) = filt_wave(im_jpg(:,:,1),opts);
data_filt(:,:,2) = filt_wave(im_jpg(:,:,2),opts);
data_filt(:,:,3) = filt_wave(im_jpg(:,:,3),opts);
imshow(data_filt);


% %         data_filt = filt_CT(data_filt,opts);
% 
% data_filt = fcn_hsnsctshrink(double(data),{'maxflat','dmaxflat5'},opts.nlevs,2.^(-length(opts.nlevs)+1:1:0));
% data_filt = max(data_filt,0);
