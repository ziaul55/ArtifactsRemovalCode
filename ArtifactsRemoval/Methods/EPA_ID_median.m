function im_res = EPA_ID_median(im, opts)
%EPA_ID_MEDIAN EPA_ID algorithm with median filter
% im - jpg image (uint8)
% opts - structure with following parameters
% - Size - size of the filter
% - CutPoint - image cut point opts.CutPoint == {[1 1]}
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
im_edges_binary=delete_false_edges(im_edges_binary, n, m, opts.CutPoint{1});
im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));

for i=1:d
    im_edges=all_edges(:,:,i).*im_edges_binary_open;
    map_edges = imcomplement(im_edges);

    % make a weight map
    W = medfilt2(map_edges,[opts.Size  opts.Size]);

    % filter whole image layer
    im_res(:,:,i) = medfilt2(im(:,:,i) .* map_edges, ...
        [opts.Size  opts.Size]) ./ W;

end
end

