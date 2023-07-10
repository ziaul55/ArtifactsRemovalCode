function im_res = EPA_ID_wave(im, opts)
%EPA_ID_WAVE EPA_ID algorithm with the 2D wavelet decomposition
% im - jpg image (uint8)
% opts - structure with following parameters
% wname - wavelet type
% thr_type -  {default}   - use ddencmp function - default values for denoising or compression
%             {penalized} - Estimate the noise standard deviation from the detail coefficients at given level.
% alpha - penalization parameter
% level - decomposition level
% keepapp - Threshold approximation setting, If keepapp = 1, the approximation coefficients are not thresholded.
% CutPoint - image cut point
% returns - im_res - filtred image (uint8)

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
    [T, ~]=graythresh(gmag_grayscale); % Otsu algorithm

    gmag_grayscale_bin = gmag_grayscale;
    gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0;
    gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;
    all_edges_bin(:,:,i)=gmag_grayscale_bin;

    gmag_grayscale(gmag_grayscale <= T) = 0;
    gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  
    all_edges(:,:,i) = gmag_grayscale ./(1-T);
end

% Prepare the binary map of edges
im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
im_edges_binary=delete_false_edges(im_edges_binary, n, m, opts.CutPoint);
im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));

for i=1:d
    im_edges=all_edges(:,:,i).*im_edges_binary_open;
    map_edges = imcomplement(im_edges);

    % make a weight map
    W = filt_wave(map_edges,opts);

    % filter whole image layer
    im_res(:,:,i) = filt_wave(im(:,:,i) .* map_edges, ...
        opts) ./ W;

end
end

