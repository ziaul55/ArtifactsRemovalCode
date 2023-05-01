% Load WSI
destination="..\Datasets\TCGA.svs";
wadapter = images.blocked.TIFF;
bim = blockedImage(destination,Adapter=wadapter); % is readonly
bim2 = blockedImage("test3.tiff",Adapter=wadapter);
desc.Img="pp";
bim.UserData = desc;

write(bim, "test3.tiff", "Adapter", wadapter,"Levels",1);

 
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

%%

 wadapter = images.blocked.TIFF; 
 write(benh, "test2.tiff", "Adapter", wadapter);
 %%
 l1=imread("test2.tiff");

l2=imresize(gather(benh,"Level",1), 0.25);
l3=imresize(l2, 0.5);
l4 = imresize(l3,0.5);

% gather layers from the original image (with labels)
l5 = gather(bim, "Level",5);
l6 = gather(bim, "Level",6);
l7 = gather(bim, "Level",7);


% append layers to the file
data.ImageDescription = original_desc(2).ImageDescription;
imwrite(l2,"test.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(3).ImageDescription;
imwrite(l3,"test.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(4).ImageDescription;
imwrite(l4,"test.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(5).ImageDescription;
imwrite(l5,"test.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(6).ImageDescription;
imwrite(l6,"test.tiff","tiff","WriteMode","append","Description",data.ImageDescription);

data.ImageDescription = original_desc(7).ImageDescription;
imwrite(l7,"test.tiff","tiff","WriteMode","append","Description",data.ImageDescription);



%%
inFile        = 'test2.tif';
inFileInfo    = imfinfo(inFile);
outFile       = 'test.tif';
tileSize      = [128, 128]; % has to be a multiple of 16.
outFileWriter = bigTiffWriter(outFile, inFileInfo(1).Height, inFileInfo(2).Width, tileSize(1), tileSize(2));
blockproc(inFile, tileSize, 'Destination', outFileWriter);
outFileWriter.close();

%img=imread(['test2.tiff'],'Index',1,'PixelRegion', {[1,16000],[1,16000]});