function im_res= test_cuda(type, size_f, sigma, im_jpg)

% gpuArray double
im=im2double(im_jpg);

% prepare filter
filt=filters(type, size_f, sigma);

% preallocate memory gpuArrays
[n, m, d] = size(im);
im_res=gpuArray(zeros(n,m,d,'double'));
all_edges = gpuArray(zeros(n, m, d, 'double'));
all_edges_bin=gpuArray(zeros(n,m,d,'logical'));

% detect edges
for i=1:d
    % extract a layer
    layer = im(:,:,i);
    % count gradients
    [gmag, ~] = imgradient(layer, 'central');
    gmag_grayscale = mat2gray(gmag);
    
    % detect edges 
    [T, ~]=graythresh(gmag_grayscale); % Computes treshold value (Otsu algorithm)
    gmag_grayscale_bin = gmag_grayscale;

    gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0; % if pixel value is below treshold replace it with 0
    gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;
    all_edges_bin(:,:,i)=gmag_grayscale_bin;

    gmag_grayscale(gmag_grayscale <= T) = 0; % if pixel value is below treshold replace it with 0
    gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  % (pixel-treshold)
    all_edges(:,:,i) = gmag_grayscale ./(1-T); %(pixel - treshold)/(1-treshold) or 0/(1-treshold)=0
end

% make a map of the edges ( edge in three channels => 0, compression grid and other => 1 )
im_edges_binary= logical(sum(all_edges_bin, 3) == 3);
im_edges_binary= logical(additional_functions.delete_false_edges(im_edges_binary, n, m, [1 1]));
im_edges_binary = imopen(im_edges_binary, strel('square',2));

% make a filter based on the chosen sigma
filter_mask=make_filter(filt);

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
%cast to uint8
            im_res = im2uint8(im_res);
end

