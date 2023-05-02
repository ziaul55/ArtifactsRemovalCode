function mbim = load_wsi_func(filepath, output, blocksize, parallel, filt_size, sigma, res_path, gpu)
%LOAD_WSI_FUNC Function to read and process a WSI image
% filepath - WSI localization
% output - path for folder with binary files created during block
% processing
% blocksize - size of a block
% filt_size - size of a filter kernel
% sigma - std of a gaussian filter
% res_path - path for the result image
% gpu - use gpu or not
% returns: mbim - processed blocked image

% load blocked image
bim = blockedImage(filepath);


% count tresholds for each color channel (otsu method)
layer=gather(bim,"Level",3);
params = zeros(3,1, 'double');

for i=1:3
    [gmag, ~] = imgradient(layer(:,:,i), 'central');
    gmag_grayscale = mat2gray(gmag);
    params(i)=graythresh(gmag_grayscale);
end

% remove artifacts (block processing)

benh= apply(bim,...
    @(bs)method2_WSI(bs.Data, params, sigma, filt_size,gpu),...
    "BorderSize", [filt_size filt_size],"Level",1, "UseParallel",parallel,"OutputLocation",output,"BlockSize",blocksize);


% get original ImageDescription
original_desc = imfinfo(filepath);

% save first layer ( use Tiff because of the high resolution )
l1=gather(benh);
t = Tiff(res_path,"w8");
tagstruct.Photometric = Tiff.Photometric.RGB;
tagstruct.ImageLength = size(l1,1);
tagstruct.ImageWidth = size(l1,2);
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.SamplesPerPixel = 3;
tagstruct.Compression = Tiff.Compression.None;
tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
tagstruct.BitsPerSample = 8;
tagstruct.RowsPerStrip = 512;
tagstruct.ImageDescription = original_desc(1).ImageDescription;
t.setTag(tagstruct);
t.write(l1);
t.close();

% resize layers
l2 = imresize(l1, 0.25);
l3 = imresize(l2, 0.25);
l4 = imresize(l3,0.5);

% gather layers from the original image (with labels)
l5 = gather(bim, "Level",5);
l6 = gather(bim, "Level",6);
l7 = gather(bim, "Level",7);

% append layers to the file in the correct order
data.ImageDescription = original_desc(2).ImageDescription;
imwrite(l6,res_path,"tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(3).ImageDescription;
imwrite(l2,res_path,"tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(4).ImageDescription;
imwrite(l3,res_path,"tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(5).ImageDescription;
imwrite(l4,res_path,"tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(6).ImageDescription;
imwrite(l7,res_path,"tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(7).ImageDescription;
imwrite(l5,res_path,"tiff","WriteMode","append","Description",data.ImageDescription);

% create layers with lower resolution
% mbim = makeMultiLevel2D(benh,"Scales",[1 0.25 0.125 0.06125]);
% save image
% wadapter = images.blocked.TIFF; 
% write(mbim, res_path, "Adapter", wadapter);

end

