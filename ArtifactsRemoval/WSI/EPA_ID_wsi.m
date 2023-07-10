function im_res = EPA_ID_wsi(im_org, opts)
% EPA_ID_wsi function to remove compression artifacts from a WSI image
% im_org - compressed image block to process
% opts - structure with following parameters:
% - Params - calculated threshold values for Otsu algorithm
% - Size - size of the filter
% - Sigma - standard diviation of the gaussian filter
% - Gpu - perform calculations on GpuArrays or not
% returns im_res - processed image block
% * This function is created for block processing

im=im2double(im_org);

% create a gpu array
if opts.Gpu
    im=gpuArray(im);
end


% preallocate memory
[n, m, d] = size(im);
im_res=zeros(n,m,d,'double');
all_edges = zeros(n, m, d, 'double');
all_edges_bin=zeros(n,m,d,'logical');

for i=1:d
    T=opts.Params(i);
    % extract a layer
    layer = im(:,:,i);
    % count gradients
    [gmag, ~] = imgradient(layer, 'central');
    gmag_grayscale = mat2gray(gmag);
    % detect edges


    gmag_grayscale_bin = gmag_grayscale;
    gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0;
    gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;
    all_edges_bin(:,:,i)=gmag_grayscale_bin;


    gmag_grayscale(gmag_grayscale <= T) = 0;
    gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;
    all_edges(:,:,i) = gmag_grayscale ./(1-T);

end

% make a map of edges ( edge in three channels => 0, compression grid and other => 1 )
im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
im_edges_binary=delete_false_edges(im_edges_binary, n, m, [1 1]);
im_edges_binary = imopen(im_edges_binary, strel('square',2));

% make a filter based on the chosen sigma
filter_mask=gaussian_mask(opts.Sigma, opts.Size);

for i=1:d
    % create map for each layer
    im_edges=all_edges(:,:,i).*im_edges_binary;
    map_edges = imcomplement(im_edges);

    % make a weights map for each layer
    W = imfilter(map_edges, filter_mask, 'symmetric', 'conv');

    % filter whole image layer
    im_res(:,:,i) = imfilter(im(:,:,i) .* map_edges, ...
        filter_mask, 'symmetric', 'conv') ./ W;
end

im_res=im2uint8(im_res);

% gather block from gpu
if opts.Gpu
    im_res=gather(im_res);
end

end