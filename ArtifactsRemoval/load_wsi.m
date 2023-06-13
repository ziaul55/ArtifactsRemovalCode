% Load WSI
destination="org_7layers.svs";%"..\Datasets\TCGA.svs";
wadapter = images.blocked.TIFF();
bim = blockedImage(destination,Adapter=wadapter); % is readonly
info_org = imfinfo(destination);

% check number of rescaled levels - the number can be different for
% differen WSI images

% convert info to a table 
inf_org_tab  = struct2table(info_org);

% number of layers
num_layers = height(inf_org_tab);

% add original layers indexes to the table
inf_org_tab.order = transpose(1:num_layers);

% sort layers by dimmensions (like in the blockedImage)
inf_org_tab = sortrows(inf_org_tab, 'Height', 'descend');

% extract info about layers to process
% check if strips per offset is empty

emptyCell = cell(1,1);
rows = zeros(num_layers,1, "logical");
for i=1:num_layers
    rows(i) = isequal(inf_org_tab.StripOffsets(i),emptyCell);
end
inf_org_process = inf_org_tab(rows, :);
num_layers_process=height(inf_org_process);

% if the number of layers is smaller than 3 - calculate the third layer 
% in order to caltulate the tresholds

% there is only one layer
if num_layers_process==1
    layer = imresize(gather(bim,"Level",1),0.125);
    % there are two layers
elseif num_layers_process==2
    layer = imresize(gather(bim,"Level",1),0.25);
else % there are at least three layers
    layer=gather(bim,"Level",3);
end

% count tresholds for each color channel (otsu method)
params = zeros(3,1, 'double');

for i=1:3
    [gmag, ~] = imgradient(layer(:,:,i), 'central');
    gmag_grayscale = mat2gray(gmag);
    params(i)=graythresh(gmag_grayscale);
end


% remove artifacts (block processing)
sigma = 1.7;
size_filt = 5;
[layer1, psnr_vals]= apply(bim,...
    @(bs)method2_WSI(bs.Data, params, sigma, size_filt, true),...
    "BorderSize", [size_filt size_filt],"Level",1, "UseParallel",true,"OutputLocation","..\output12\","BlockSize",[1024 1024]);

layer1_org = gather(bim, "Level",1);

mse = sum(gather(psnr_vals));
mse = mse/(size(layer1_org,1)*size(layer1_org,2));
psnr_score = 10*log10((255*255)/mse);

% Save image

% calculate scales for next layers
scales = zeros(num_layers_process-1, 1, "double");

for i=2:num_layers_process
    scales(i-1) = round((inf_org_process(i,:).Height/inf_org_process(i-1,:).Height),2);
end

% due to the large size use TiffLib instead of imwrite
%% compression, ssim, psnr, filtracja 
img_name = "2layers.svs";
current_layer=gather(layer1);
for i=1:num_layers_process

    if i>1
        current_layer = imresize(current_layer, scales(i-1));
    end
        

    info=table2struct(inf_org_tab(i,:));

    if i==1
        img_save = Tiff(img_name,'w8');
    else
        img_save = Tiff(img_name,'a');
    end
    tags.ImageLength = size(current_layer,1);
    tags.ImageWidth = size(current_layer,2);
    tags.Photometric = Tiff.Photometric.RGB;
    tags.BitsPerSample = info.BitsPerSample(1);
    tags.SamplesPerPixel = size(current_layer,3);
    tags.RowsPerStrip = info.RowsPerStrip;
    tags.TileWidth = info.TileWidth;
    tags.TileLength = info.TileLength;
    tags.Compression = Tiff.Compression.PackBits;
    tags.ImageDescription = info.ImageDescription;
    tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tags.Software = 'MATLAB';
    tags.MaxSampleValue = info.MaxSampleValue(1);
    tags.MinSampleValue = info.MinSampleValue(1);

    setTag(img_save, tags);
    write(img_save,  current_layer);
    close(img_save) 
end

%% save information layers
if num_layers>num_layers_process

    for i=num_layers_process+1:num_layers

        info=table2struct(inf_org_tab(i,:));
        img_save = Tiff(img_name,'a');
        current_layer=gather(bim, "Level",i);
        imwrite(current_layer,img_name,"tif","WriteMode","append","Description",info.ImageDescription,...
            "RowsPerStrip",info.RowsPerStrip);
    end
end



%%
img=imread('7layers.svs','Index',2,'PixelRegion', {[1,16000],[1,16000]});
imshow(img);
