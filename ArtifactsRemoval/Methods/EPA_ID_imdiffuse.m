function im_res = EPA_ID_imdiffuse(im, opts)
%EPA_ID_IMDIFFUSSE Anisotropic diffusion filtering, the number of
% iterations and the threshold value are calculated with the imdiffuseest
% function
% INFO: does not support gpuArrays
% im - jpg image (uint8)
% opts - structure with following parameters
% - ConductionMethod - "exponential" or "quadratic"
% - Connectivity - "minimal" or "maximal"
% - CutPoint - image cut point
% returns im_res - filtred image

im=im2double(im);

% preallocate memory
[n, m, d] = size(im);
im_res=zeros(n, m, d, "double");
all_edges = zeros(n, m, d, 'double'); 
all_edges_bin=zeros(n,m,d,'logical');

for i=1:d
    % extract a layer
    layer = im(:,:,i);
    % count gradients
    [gmag, ~] = imgradient(layer, 'central');
    gmag_grayscale = mat2gray(gmag);
    % detect edges
    [T, ~]=graythresh(gmag_grayscale); % Otsu

    gmag_grayscale_bin = gmag_grayscale;
    gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0;
    gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;
    all_edges_bin(:,:,i)=gmag_grayscale_bin;

    gmag_grayscale(gmag_grayscale <= T) = 0; 
    gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;
    all_edges(:,:,i) = gmag_grayscale ./(1-T); 
end

% Prepare binary map of edges
im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
im_edges_binary=delete_false_edges(im_edges_binary, n, m, opts.CutPoint);
im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));

for i=1:d
    im_edges=all_edges(:,:,i).*im_edges_binary_open;
    map_edges = imcomplement(im_edges);

    [gradThresh,numIter] = imdiffuseest(map_edges, "ConductionMethod",opts.ConductionMethod,"Connectivity",opts.Connectivity);

    % make a weight map
    % W = imfilter(map_edges, filter_mask, 'symmetric', 'conv');
    W = imdiffusefilt(map_edges, 'GradientThreshold', ...
        gradThresh,'NumberOfIterations',numIter,"ConductionMethod",opts.ConductionMethod,"Connectivity",opts.Connectivity);

    [gradThresh,numIter] = imdiffuseest(im(:,:,i), "ConductionMethod",opts.ConductionMethod,"Connectivity",opts.Connectivity);
    % filter whole image layer
    im_res(:,:,i) = imdiffusefilt(im(:,:,i) .* map_edges, ...
        'GradientThreshold', ...
        gradThresh,'NumberOfIterations',numIter,"ConductionMethod",opts.ConductionMethod,"Connectivity",opts.Connectivity) ./ W;
end

im_res = im2uint8(im_res);



