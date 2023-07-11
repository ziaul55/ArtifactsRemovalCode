function im_res = EPA_ID_guided(im,opts)
%EPA_ID_GUIDED EPA_ID algorithm with guided filtration
% INFO: does not support gpuArrays
% im - jpg image (uint8)
% opts - structure with following parameters
% - CutPoint - image cut point opts.CutPoint == {[1 1]}
% - DoS - degree of smoothing
% - NeighSize - neighborhood size
% im_res - filtred image

im=im2double(im);

% preallocate memory
[n, m, d] = size(im);
im_res=zeros(n, m, d, "double");
all_edges = zeros(n, m, d, 'double');
all_edges_bin=zeros(n,m,d,'logical');

% detect all edges for each image layer
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
im_edges_binary=delete_false_edges(im_edges_binary, n, m, opts.CutPoint{1});
im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));

for i=1:d
    im_edges=all_edges(:,:,i).*im_edges_binary_open;
    map_edges = imcomplement(im_edges);

    % make a weight map
    W = imguidedfilter(map_edges, "DegreeOfSmoothing", opts.DoS, "NeighborhoodSize",opts.NeighSize);

    % filter whole image layer
    im_res(:,:,i) = imguidedfilter(im(:,:,i) .* map_edges, ...
        "DegreeOfSmoothing", opts.DoS, "NeighborhoodSize",opts.NeighSize) ./ W;
end

im_res = im2uint8(im_res);
end

