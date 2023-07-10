function true_edges = delete_false_edges(im, n, m, cut_point)
%DELETE_FALSE_EDGES function to detect jpg compression grid
% copies the real edges and removes false edges from the image
% im - image
% n, m - size of an image
% cut_point - vector, containing the image grid coordinates,
% if the image is a fragment of a compressed image

% set borders 8x8 blocks to 0
% count needed shifts caused by the very original image cut_point
shift_r = mod(cut_point(1), 8) - 1;
shift_c = mod(cut_point(2), 8) - 1;

% select rows to be copied
rows = 1:n;
rows = rows(mod(rows+shift_r, 8) ~= 0);
rows = rows(mod(rows+shift_r, 8) ~= 1);

% select columns to be copied
cols = 1:m;
cols = cols(mod(cols+shift_c, 8) ~= 0);
cols = cols(mod(cols+shift_c, 8) ~= 1);

% copy only true edges
true_edges = zeros(n, m, class(im));
true_edges(rows, cols) = im(rows, cols);
end
