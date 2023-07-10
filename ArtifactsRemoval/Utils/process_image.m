function im_res = process_image(im,opts, method, gpu)
%PROCESS_IMAGE function to process the image with the chosen method
% im - jpg image (uint8)
% opts - structure with method's parameters
% method - name of the method

if(gpu)
    im = gpuArray(im);
end

switch method
    case 'imbilateral_filtering'
        im_res = imbilateral_filtering(im, opts);
    case 'avg_filtering'
        im_res = avg_filtering(im, opts);
    case 'gaussian_filtering'
        im_res = gaussian_filtering(im, opts);
    case 'median_filtering'
        im_res = median_filtering(im, opts);
    case 'wiener_filtering'
        im_res = wiener_filtering(im, opts);
    case 'guided_filtering'
        im_res = guided_filtering(im, opts);
    case 'non_local_means_filtering'
        im_res = non_local_means_filtering(im, opts);
    case 'imdiffuse_filtering'
        im_res = imdiffuse_filtering(im, opts);
    case 'wave_filtering'
        im_res = wave_filtering(im, opts);
    case 'EPA_ID_wave'
        im_res = EPA_ID_wave(im, opts);
    case 'EPA_ID_gauss'
        im_res = EPA_ID_gauss(im, opts);
    case 'EPA_ID_avg'
        im_res = EPA_ID_avg(im, opts);
    case 'EPA_ID_median'
        im_res = EPA_ID_median(im, opts);
    case 'EPA_ID_wiener'
        im_res = EPA_ID_wiener(im, opts);
    case 'EPA_ID_non_local_means'
        im_res = EPA_ID_non_local_means(im, opts);
    case 'EPA_ID_imdiffuse'
        im_res = EPA_ID_imdiffuse(im, opts);
    case 'EPA_ID_guided'
        im_res = EPA_ID_guided(im, opts);
    case 'EPA'
        im_res = EPA(im, opts);
    case 'EPA_ID_W'
        im_res = EPA_ID_W(im, opts);
    case 'MMWF_2D_filtering'
        im_res = MMWF_2D_filtering(im, opts);
end

if(gpu)
    im_res = gather(im_res);
end

