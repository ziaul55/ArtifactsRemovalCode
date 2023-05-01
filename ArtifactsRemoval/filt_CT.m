function data_filt = filt_CT(data,opts)

im = imresize(double(data)/max(double(data(:))),[512,512]);
sigma = std(im(:));

%%%%% Contourlet Denoising %%%%%
% Contourlet transform
y = pdfbdec(im,opts.pfilt,opts.dfilt,opts.nlevs);
[c, s] = pdfb2vec(y);

% % Threshold
% % Require to estimate the noise standard deviation in the PDFB domain first 
% % since PDFB is not an orthogonal transform
% nvar = pdfb_nest(size(im,1),size(im,2),opts.pfilt,opts.dfilt,opts.nlevs);
% cth = opts.thr * sigma * sqrt(nvar);
% 
% % Slightly different thresholds for the finest scale
% fs = s(end, 1);
% fssize = sum(prod(s(s(:, 1) == fs, 3:4), 2));
% cth(end-fssize+1:end) = (4/3) * cth(end-fssize+1:end);
% c = c .* (abs(c) > cth);

% Estimation of standard deviation
fs = s(end, 1);
fssize = sum(prod(s(s(:, 1) == fs, 3:4), 2));
hh1 = c(end-fssize+1:end); %finest wavelet coefs
esigma = median(abs(hh1(:)))/.6745;
ve = esigma^2;

% Subband dependent thresholding
valueNC = cell(length(valueC),1);
valueNC{1} = valueC{1}; % Lowest component
nLevels = length(valueC);
for iLevel=2:nLevels
    nDirs = length(valueC{iLevel});
    for iDir = 1:nDirs
        c = valueC{iLevel}{iDir};
        vy = var(c(:));
        ven = ve*nw(iLevel-1); % Level dependent weight adjustment        
        sigmax = sqrt(max(vy-ven,0));
        T = min(ven/sigmax,max(abs(c(:))));
        nc = (abs(c(:))-T);
        nc(nc<0) = 0;
        valueNC{iLevel}{iDir} = sign(c).*reshape(nc,size(c));
    end
end

% Reconstruction
y = vec2pdfb(c, s);
cim = pdfbrec(y,opts.pfilt,opts.dfilt);

data_filt = imresize(255 * cim,size(data));
data_filt = max(0,data_filt);

figure; subplot(1,2,1);imshow(255-data,[]); subplot(1,2,2); imshow(255-data_filt,[])
figure; subplot(1,2,1);imagesc(1-im,[min(1-im(:)),1]); subplot(1,2,2); imagesc(1-cim,[min(1-cim(:)),1]); colormap('gray');    