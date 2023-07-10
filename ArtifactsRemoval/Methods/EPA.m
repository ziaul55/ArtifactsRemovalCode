function im_res = EPA(im, opts)
%EPA - edge-preserving artifacts removal method
% P. Jóźwik-Wabik et al., „Removing compression artifacts on whole 
% slide HE-stained histopathological images",  Recent advances 
% in computational oncology and personalized medicine, 
% S. Bajkacz i Z. Ostrowski, Red. 2021, s. 79–88."
% @input im - the jpg image (uint8)
% @input opts - struct with following parameters:
% - Sigma - sigma parameter for Gaussian filter
% - Size - kernel size
% - CutPoint
% @output im_res - the image without artifacts

im = im2double(im);

% preallocate memory
[n, m, d] = size(im);
all_edges = zeros(n, m, d, 'logical');

% detect all edges for each image layer
for i=1:d
    % extract a layer
    layer = im(:,:,i);

    % count gradients
    [gmag, ~] = imgradient(layer, 'central');
    gmag_grayscale = mat2gray(gmag);

    % detect edges (Otsu)
    [T, ~]=graythresh(gmag_grayscale);

    gmag_grayscale_bin = gmag_grayscale;
    gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0;
    gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;
    all_edges(:,:,i)=gmag_grayscale_bin;

end

% make a map of the edges
im_edges = logical(sum(all_edges, 3) == 3); % sum ones
im_edges = delete_false_edges(im_edges, n, m, opts.CutPoint);
im_edges = imopen(im_edges, strel('square',2));
map_edges = im2double(~im_edges);

% make a filter based on the chosen parameters
filter_mask=gaussian_mask(opts.Sigma, opts.Size);

% make a weight map
W = imfilter(map_edges, filter_mask, 'symmetric', 'conv');

% filter whole image
im_res = imfilter(im .* map_edges, ...
    filter_mask, 'symmetric', 'conv') ./ W;

% correct null values
im_res(isnan(im_res))=im(isnan(im_res));
im_res = im2uint8(im_res);
end

