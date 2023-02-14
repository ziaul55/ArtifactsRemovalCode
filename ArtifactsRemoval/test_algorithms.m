% script to detect and remove JPG compression artifacts for one image

% read an .tif image an convert it to uint8
[im_file, im_path] = uigetfile({'*.tif' ; '*.tiff'}, 'Select an image');
im_org_uint16 = imread([im_path '\' im_file]);
im_org = additional_functions.conv_to_uint8(im_org_uint16);

% compress to jpg
imwrite(im_org, 'jpg_conv.jpg', 'jpg', 'Quality', 30);
im_jpg= imread('jpg_conv.jpg');

% parameters
method="method_1";
sigma=2.9;
filter_size=5;
filter_type="gauss";

% remove artifacts
rem = remove_artifacts(im_jpg, [1 1], sigma,...
    filter_size,filter_type, method);

im=run_artifacts_removal(rem);

% crop and show images
rect=[100 100 200 200];
crop_im=imcrop(im, rect);
crop_org=imcrop(im_org, rect);
crop_jpg=imcrop(im_jpg, rect);
montage({crop_org, crop_jpg, crop_im},"Size",[1 3]);
