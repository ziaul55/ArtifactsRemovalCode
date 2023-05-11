function [data_filt,thr] = filt_wave(data,opts)

%perform 2D wavelet decomposition
[C,S] = wavedec2(data,opts.level,opts.wname);

switch opts.thr_type
    case 'penalized'    %Birgé-Massart
        % Estimate the noise standard deviation from the
        % detail coefficients at given level .
        det1 = detcoef2('compact',C,S,opts.level);
        sigma = median(abs(det1))/0.6745;
        thr = wbmpen(C,S,sigma,opts.alpha);
    case 'default'  %Donoho and Johnstone      
        thr = ddencmp('den','wv',data);
end

data_filt = wdencmp('gbl',C,S,opts.wname,opts.level,thr,'s',opts.keepapp);
data_filt = max(0,data_filt);

figure; 
%subplot(1,2,1);
%imshow(255-data,[]); 
%subplot(1,2,2); 
imshow(255-data_filt,[])
