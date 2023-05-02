% Load WSI
destination="..\Datasets\TCGA.svs";
wadapter = images.blocked.TIFF;
bim = blockedImage(destination,Adapter=wadapter); % is readonly

 
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
    @(bs)method2_WSI(bs.Data, params, sigma, size_filt, true),...
    "BorderSize", [size_filt size_filt],"Level",1, "UseParallel",true,"OutputLocation","..\output\","BlockSize",[1024 1024]);

original_desc = imfinfo(destination);

l1=gather(benh);
t = Tiff("test2.tiff","w8");
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

wadapter = images.blocked.TIFF; 

write(benh, "test.tiff", "Adapter", wadapter);

l2=imresize(l1, 0.25);
l3=imresize(l2, 0.25);
l4 = imresize(l3,0.5);

% gather layers from the original image (with labels)
l5 = gather(bim, "Level",5);
l6 = gather(bim, "Level",6);
l7 = gather(bim, "Level",7);

% append layers to the file
data.ImageDescription = original_desc(2).ImageDescription;
imwrite(l6,"test2.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(3).ImageDescription;
imwrite(l2,"test2.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(4).ImageDescription;
imwrite(l3,"test2.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(5).ImageDescription;
imwrite(l4,"test2.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(6).ImageDescription;
imwrite(l7,"test2.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(7).ImageDescription;
imwrite(l5,"test2.tiff","tiff","WriteMode","append","Description",data.ImageDescription);





%img=imread(['test.tiff'],'Index',1,'PixelRegion', {[1,16000],[1,16000]});