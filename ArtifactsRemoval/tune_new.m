% loader = file_operations("inputfile.json");
% loader = loader.prepare_tabels();
% loader.tune_parameters()

sigma=0.7;
filter_type="gauss";
filter_size=5;

% read an .tif image an convert it to uint8
[im_file, im_path] = uigetfile({'*.tif' ; '*.tiff'}, 'Select an image');
im_org_uint16 = imread([im_path '\' im_file]);
im_org = additional_functions.conv_to_uint8(im_org_uint16);

% compress to jpg
imwrite(im_org, 'jpg_conv.jpg', 'jpg', 'Quality', 30);
im_jpg= imread('jpg_conv.jpg');

% array to gpu
im_jpg_gpu=gpuArray(im_jpg);

rem = remove_artifacts(im_jpg, [1 1], sigma,...
    filter_size,filter_type, "method_2");
tic
im_res1=run_artifacts_removal(rem);
toc

% 0.316418

tic
im_res2 = test_cuda(filter_type, filter_size, sigma, im_jpg_gpu);
toc

