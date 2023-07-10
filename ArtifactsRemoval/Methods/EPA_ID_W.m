function im_res = EPA_ID_W(im, opts)
%EPA_ID_W artifact removal method
% im - jpg image (uint8)
% opts - structure with following parameters:
% - Size - size of the gaussian filter
% - Sigma - stdev of the gaussian filter
% - CutPoint - the cut point for the image (8x8 grid position)
% returns im_res filtred image

im=im2double(im);

% preallocate memory
[n, m, d] = size(im);
im_res=zeros(n, m, d, "double");
all_edges = zeros(n, m, d, 'double'); 
all_edges_bin=zeros(n,m,d,'logical');

% detect all edges for each image layer
for i=1:d
   
    layer = im(:,:,i);

    [gmag, ~] = imgradient(layer, 'central');
    gmag_grayscale = mat2gray(gmag);
    % detect edges
    [T, ~]=graythresh(gmag_grayscale); % calculate treshold value (Otsu algorithm)

    gmag_grayscale_bin = gmag_grayscale;
    gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0;
    gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;
    all_edges_bin(:,:,i)=gmag_grayscale_bin;

    gmag_grayscale(gmag_grayscale <= T) = 0; % if pixel value is below treshold replace it with 0
    gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  % (piksel-treshold)
    all_edges(:,:,i) = gmag_grayscale ./(1-T); 
end

% Prepare binary map of edges
im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
im_edges_binary=delete_false_edges(im_edges_binary, n, m, opts.CutPoint);
im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));
map_edges_binary=double(~im_edges_binary_open);

% Create a filter mask
filter_mask=gaussian_mask(opts.Sigma, opts.Size);

% Prepare weights matrix
W2 = imfilter(map_edges_binary, filter_mask, 'symmetric', 'conv');

% Create result image
im_res_bin = imfilter(im .* map_edges_binary, ...
    filter_mask, 'symmetric', 'conv') ./ W2;

% Remove black pixels
im_res_bin(isnan(im_res_bin))=im(isnan(im_res_bin));

for i=1:d
    im_edges=all_edges(:,:,i).*im_edges_binary_open;
    map_edges = imcomplement(im_edges);

    % make a weight map
    W = imfilter(map_edges, filter_mask, 'symmetric', 'conv');

    % filter whole image layer
    im_res(:,:,i) = imfilter(im(:,:,i) .* map_edges, ...
        filter_mask, 'symmetric', 'conv') ./ W;

    % add results with correct weights
    im_res(:,:,i)=im_res(:,:,i).*map_edges+(1.- map_edges).*im_res_bin(:,:,i);
end

im_res=im2uint8(im_res);

end