function [im_res, psnr_val, ssim_val] = method2_WSI(im_org, params, sigma, size_filt, gpu)
%METHOD2_WSI function to remove compression artifacts from a WSI image
% im - image (or block) to process
% params - vector of threshold values (for each color channel)
% size - size of the gaussian filter
% sigma - stddev of the gaussian filter
% gpu - use gpu or not
% returns im_res - processed image (or block)
% * This function is suitable for block processing
         
            im=im2double(im_org);

            % create a gpu array
            if gpu
                im=gpuArray(im);
            end
            filt=filters('gauss', size_filt, sigma);

            % preallocate memory
            [n, m, d] = size(im);
            im_res=zeros(n,m,d,'double');
            all_edges = zeros(n, m, d, 'double');
            all_edges_bin=zeros(n,m,d,'logical');

            for i=1:d
                T=params(i);
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

            % make a map of the edges ( edge in three channels => 0, compression grid and other => 1 )
            im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
            im_edges_binary=additional_functions.delete_false_edges(im_edges_binary, n, m, [1 1]);
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
            
            im_res=im2uint8(im_res);

            % gather block from gpu
            if gpu
                im_res=gather(im_res);
            end
            [psnr_val,ssim_val] = quality_metrics.count_metrics(im_org, im_res);
           
        end