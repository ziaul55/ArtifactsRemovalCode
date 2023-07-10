function im_res = wiener_filtering(im,opts)
%WIENER_FILTERING function to perform filtering with wiener filter
% im - jpg image (uint8)
% opts - structure with following parameters
% - Size - size of the filter

im = im2double(im);
[n, m, d] = size(im);
im_res=zeros(n,m,d,'double');
for i=1:d
    im_res(:,:,i) = wiener2(im(:,:,i), [opts.Size opts.Size]);
end

im_res = im2double(im_res);

end

