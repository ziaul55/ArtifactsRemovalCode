% Load WSI  
 bim = blockedImage("..\Datasets\TCGA.svs");


% count tresholds for each color channel (otsu method)
layer=gather(bim,"Level",3);
params = zeros(3,1, 'double');

for i=1:3
    [gmag, ~] = imgradient(layer(:,:,i), 'central');
    gmag_grayscale = mat2gray(gmag);
    params(i)=graythresh(gmag_grayscale);
end

% remove artifacts (block processing)
sigma = 1.4;
size_filt = 3;
benh= apply(bim,...
    @(bs)method2_WSI(bs.Data, params, sigma, size_filt),...
    "BorderSize", [size_filt size_filt],"Level",1, "UseParallel",true,"OutputLocation","..\output9\","BlockSize",[1024 1024]);


% create layers with lower resolution
mbim = makeMultiLevel2D(benh,"Scales",[1 0.25 0.125 0.06125]);

% save image
 wadapter = images.blocked.TIFF; 
% write(mbim, "processed2.svs", "Adapter", wadapter);

img=imread(['processed.svs'],'Index',1,'PixelRegion', {[1,16000],[1,16000]});