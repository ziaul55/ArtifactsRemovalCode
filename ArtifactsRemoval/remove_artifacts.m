classdef remove_artifacts
    %REMOVE_ARTIFACTS class to perform artifacts removal operations

    properties
        Image % image to process
        CutPoint % image cut point
        Sigma % sigma value
        FilterSize % size of the filter
        FilterType % type of the filter
        Method % type of removal algorithm
    end

    methods
        function obj = remove_artifacts(im, cut_point,sigm, filter_size,...
                filter_type, method)
            %REMOVE_ARTIFACTS Construct an instance of the remove_artifacts
            %class
            obj.CutPoint=cut_point;
            obj.Image=im;
            obj.Sigma=sigm;
            obj.FilterSize=filter_size;
            obj.FilterType=filter_type;
            obj.Method=method;
        end

        function im_res = run_artifacts_removal(obj)
            %RUN_ARTIFACTS_REMOVAL method removes artifacts
            %   Method removes artifacts with chosen methods and filters

            switch obj.Method
                case 'method_1'
                    im_res = run_method_1(obj);
                case 'method_2'
                    if obj.FilterType == "wiener"
                        im_res = run_method_2_wiener(obj);
                    elseif obj.FilterType == "median"
                        im_res = run_method_2_median(obj);
                    elseif obj.FilterType == "wave"
                        im_res = run_method_2_wave(obj);
                    elseif obj.FilterType == "guided"
                        im_res = run_method_2_imguided(obj);
                    elseif obj.FilterType == "non_local_means"
                        im_res = run_method_2_imlmfilt(obj);
                    else
                        im_res = run_method_2(obj);
                    end
                case 'method_3'
                    im_res = run_method_3(obj);
                case 'blur'
                    im_res = run_blur(obj);
                case 'wave'
                    im_res = run_wave(obj);
                case 'method_2_wave'
                    im_res = run_method_2_wave(obj);
            end

            % cast to uint8
            im_res = im2uint8(im_res);
            im_res = gather(im_res);
        end

        function im_res = run_wave(obj)
            im=im2double(obj.Image);

            opts.wname ='db3';           % wavelet type
            opts.thr_type = 'penalized'; % {default} - use ddencmp function - default values for denoising or compression                                 
                                         % {penalized} - Estimate the noise standard deviation from the detail coefficients at given level.
            opts.alpha = 5;              % penalization parameter
            opts.level = 2;              % decomposition level
            opts.keepapp = 1;            % Threshold approximation setting, If keepapp = 1, the approximation coefficients are not thresholded.

            [n, m, d] = size(im);
            im_res = zeros(n, m, d, 'double');

            for i=1:d
                im_res(:,:,i) = filt_wave(im(:,:,i),opts);
            end
        end

        function im_res = run_method_1(obj)
            %RUN_OTSU artifacts removal method
            % function uses otsu algorithm in order to create a map of edges
            im=im2double(obj.Image);
            filter_type=obj.FilterType;
            filter_size=obj.FilterSize;
            sigm=obj.Sigma;
            % preallocate memory
            [n, m, d] = size(im);
            all_edges = zeros(n, m, d, 'logical');
            filt=filters(filter_type, filter_size, sigm);

            % detect all edges for each image layer
            for i=1:d
                % extract a layer
                layer = im(:,:,i);

                % count gradients
                [gmag, ~] = imgradient(layer, 'central');
                gmag_grayscale = mat2gray(gmag);

                % detect edges
                [T, ~]=graythresh(gmag_grayscale); % Computes treshold value (Otsu algorithm)
               
                gmag_grayscale_bin = gmag_grayscale;
                gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0; 
                gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;  
                all_edges(:,:,i)=gmag_grayscale_bin;

            end

            % make a map of the edges
            im_edges = logical(sum(all_edges, 3) == 3); % sum ones
            im_edges = additional_functions.delete_false_edges(im_edges, n, m, obj.CutPoint);
            im_edges = imopen(im_edges, strel('square',2));
            map_edges = im2double(~im_edges);

            % make a filter based on the chosen parameters
            filter_mask=make_filter(filt);

            % make a weight map
            W = imfilter(map_edges, filter_mask, 'symmetric', 'conv');

            % filter whole image
            im_res = imfilter(im .* map_edges, ...
                filter_mask, 'symmetric', 'conv') ./ W;

            im_res(isnan(im_res))=im(isnan(im_res));
        end

        function im_res = run_method_2(obj)
            %RUN_MULTILEVEL_TRESHOLDING artifact removal method
            % function uses multilevel tresholding in order to create a map of edges
            im=im2double(obj.Image);
            filter_type=obj.FilterType;
            filter_size=obj.FilterSize;
            sigm=obj.Sigma;
            filt=filters(filter_type, filter_size, sigm);

            % preallocate memory
            [n, m, d] = size(im);
            im_res=zeros(n,m,d,'double');
            all_edges = zeros(n, m, d, 'double');
            all_edges_bin=zeros(n,m,d,'logical');

            for i=1:d
                % extract a layer
                layer = im(:,:,i);
                % count gradients
                [gmag, ~] = imgradient(layer, 'central');
                gmag_grayscale = mat2gray(gmag);
                % detect edges
                [T, ~]=graythresh(gmag_grayscale); % Computes treshold value (Otsu algorithm)

                gmag_grayscale_bin = gmag_grayscale;
                gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0; 
                gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;  
                all_edges_bin(:,:,i)=gmag_grayscale_bin;


                gmag_grayscale(gmag_grayscale <= T) = 0; % if pixel value is below treshold replace it with 0
                gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  % (pixel-treshold)
                all_edges(:,:,i) = gmag_grayscale ./(1-T); %(pixel - treshold)/(1-treshold) or 0/(1-treshold)=0
              
            end

            % make a map of the edges ( edge in three channels => 0, compression grid and other => 1 )
            im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
            im_edges_binary=additional_functions.delete_false_edges(im_edges_binary, n, m, obj.CutPoint);
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
        end
        
        function im_res = run_blur(obj)
            filter_type = obj.FilterType;

            switch filter_type
                case 'gauss'
                    im_res = run_blur_mask(obj);
                case 'avg'
                    im_res = run_blur_mask(obj);
                case 'median'
                    im_res = run_blur_median(obj);
                case 'wiener'
                    im_res = run_blur_wiener(obj);
                case 'guided'
                    im_res = run_blur_guided(obj);
                case 'non_local_means'
                    im_res = run_non_local_means(obj);
                case 'imdiffusse'
                    im_res = run_imdiffusse(obj);
            end
        end

        function im_res = run_imdiffusse(obj)
            im=im2double(obj.Image);
            [n, m, d] = size(im);

            im_res=zeros(n,m,d,'double');
            for i=1:d
                im_res(:,:,i) = imdiffusefilt(im(:,:,i));
            end
        end

        function im_res = run_non_local_means(im)
            im=im2double(obj.Image);
            im = rgb2lab(im);

            % Extract a homogeneous L*a*b patch from the noisy background to compute the noise standard deviation.
            roi = [210,24,52,41];
            patch = imcrop(im,roi);

            patchSq = patch.^2;
            edist = sqrt(sum(patchSq,3));
            patchSigma = sqrt(var(edist(:)));

           % Set the 'DegreeOfSmoothing' value to be higher than the standard deviation of the patch. 
           % Filter the noisy L*a*b* image using non-local means filtering.

           DoS = 1.05*patchSigma;
           im_res = imnlmfilt(im,'DegreeOfSmoothing',DoS);
           im_res = lab2rgb(im_res,'Out','double');
        end

        function im_res = run_blur_guided(obj)
            im=im2double(obj.Image);
            [n, m, d] = size(im);

            im_res=zeros(n,m,d,'double');
            for i=1:d
                im_res(:,:,i) = imguidedfilter(im(:,:,i), "DegreeOfSmoothing", 0.004, "NeighborhoodSize",3);
            end
        end

        function im_res = run_blur_mask(obj)
            %RUN_MULTILEVEL_TRESHOLDING artifact removal method
            % function uses multilevel tresholding in order to create a map of edges
            im=im2double(obj.Image);
            filter_type=obj.FilterType;
            filter_size=obj.FilterSize;
            sigm=obj.Sigma;
            filt=filters(filter_type, filter_size, sigm);
            filter_mask=make_filter(filt);
            im_res = imfilter(im, ...
                filter_mask, 'symmetric', 'conv');
        end

        function im_res = run_blur_wiener(obj)
            im=im2double(obj.Image);
            filter_size=obj.FilterSize;
            [n, m, d] = size(im);
            im_res=zeros(n,m,d,'double');
            for i=1:d
                im_res(:,:,i) = wiener2(im(:,:,i), [filter_size filter_size]);
            end
        end

        function im_res = run_blur_median(obj)
            im=im2double(obj.Image);
            filter_size=obj.FilterSize;
            [n, m, d] = size(im);
            im_res=zeros(n,m,d,'double');
            for i=1:d
                im_res(:,:,i) = medfilt2(im(:,:,i), [filter_size filter_size]);
            end
        end


        function im_res = run_method_3(obj)
            %RUN_FIXED_MULTILEVEL_TRESHOLDING artifact removal method
            % function uses multilevel tresholding and Otsu method
            % in order to create maps of edges in the last step results
            % of both methods are added together with weights
            im=im2double(obj.Image);
            filter_type=obj.FilterType;
            filter_size=obj.FilterSize;
            sigm=obj.Sigma;
            filt=filters(filter_type, filter_size, sigm);

            % preallocate memory
            [n, m, d] = size(im);
            im_res=zeros(n, m, d, "double");
            all_edges = zeros(n, m, d, 'double'); % now numbers not logical values
            all_edges_bin=zeros(n,m,d,'logical'); % to detect ones in three channels
            % detect all edges for each image layer
            for i=1:d
                % extract a layer
                layer = im(:,:,i);
                % count gradients
                [gmag, ~] = imgradient(layer, 'central');
                gmag_grayscale = mat2gray(gmag);
                % detect edges
                [T, ~]=graythresh(gmag_grayscale); % compute treshold value (Otsu algorithm)

                gmag_grayscale_bin = gmag_grayscale;
                gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0; 
                gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;  
                all_edges_bin(:,:,i)=gmag_grayscale_bin;

                gmag_grayscale(gmag_grayscale <= T) = 0; % if pixel value is below treshold replace it with 0
                gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  % (piksel-treshold)
                all_edges(:,:,i) = gmag_grayscale ./(1-T); %(piksel - treshold)/(1-treshold) or 0/(1-treshold)=0    
            end

            % Prepare binary map of edges
            im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
            im_edges_binary=additional_functions.delete_false_edges(im_edges_binary, n, m, obj.CutPoint);
            im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));
            map_edges_binary=double(~im_edges_binary_open);

            % Create a filter mask
            filter_mask=make_filter(filt);

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
        end


        function im_res = run_method_2_wiener(obj)
            im=im2double(obj.Image);
            filter_size=obj.FilterSize;

            % preallocate memory
            [n, m, d] = size(im);
            im_res=zeros(n, m, d, "double");
            all_edges = zeros(n, m, d, 'double'); % now numbers not logical values
            all_edges_bin=zeros(n,m,d,'logical'); % to detect ones in three channels
            % detect all edges for each image layer
            for i=1:d
                % extract a layer
                layer = im(:,:,i);
                % count gradients
                [gmag, ~] = imgradient(layer, 'central');
                gmag_grayscale = mat2gray(gmag);
                % detect edges
                [T, ~]=graythresh(gmag_grayscale); % compute treshold value (Otsu algorithm)

                gmag_grayscale_bin = gmag_grayscale;
                gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0; 
                gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;  
                all_edges_bin(:,:,i)=gmag_grayscale_bin;

                gmag_grayscale(gmag_grayscale <= T) = 0; % if pixel value is below treshold replace it with 0
                gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  % (piksel-treshold)
                all_edges(:,:,i) = gmag_grayscale ./(1-T); %(piksel - treshold)/(1-treshold) or 0/(1-treshold)=0    
            end

            % Prepare binary map of edges
            im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
            im_edges_binary=additional_functions.delete_false_edges(im_edges_binary, n, m, obj.CutPoint);
            im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));
        
            for i=1:d
                im_edges=all_edges(:,:,i).*im_edges_binary_open;
                map_edges = imcomplement(im_edges);

                % make a weight map
                % W = imfilter(map_edges, filter_mask, 'symmetric', 'conv');
                W = wiener2(map_edges,[filter_size filter_size]);

                % filter whole image layer
                im_res(:,:,i) = wiener2(im(:,:,i) .* map_edges, ...
                    [filter_size filter_size]) ./ W;               
            end
        end

        function im_res = run_method_2_imguided(obj)
            im=im2double(obj.Image);
            filter_size=obj.FilterSize;

            % preallocate memory
            [n, m, d] = size(im);
            im_res=zeros(n, m, d, "double");
            all_edges = zeros(n, m, d, 'double'); % now numbers not logical values
            all_edges_bin=zeros(n,m,d,'logical'); % to detect ones in three channels
            % detect all edges for each image layer
            for i=1:d
                % extract a layer
                layer = im(:,:,i);
                % count gradients
                [gmag, ~] = imgradient(layer, 'central');
                gmag_grayscale = mat2gray(gmag);
                % detect edges
                [T, ~]=graythresh(gmag_grayscale); % compute treshold value (Otsu algorithm)

                gmag_grayscale_bin = gmag_grayscale;
                gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0; 
                gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;  
                all_edges_bin(:,:,i)=gmag_grayscale_bin;

                gmag_grayscale(gmag_grayscale <= T) = 0; % if pixel value is below treshold replace it with 0
                gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  % (piksel-treshold)
                all_edges(:,:,i) = gmag_grayscale ./(1-T); %(piksel - treshold)/(1-treshold) or 0/(1-treshold)=0    
            end

            % Prepare binary map of edges
            im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
            im_edges_binary=additional_functions.delete_false_edges(im_edges_binary, n, m, obj.CutPoint);
            im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));
        
            for i=1:d
                im_edges=all_edges(:,:,i).*im_edges_binary_open;
                map_edges = imcomplement(im_edges);

                % make a weight map
                % W = imfilter(map_edges, filter_mask, 'symmetric', 'conv');
                W = imguidedfilter(map_edges, "DegreeOfSmoothing", 0.004, "NeighborhoodSize",3);

                % filter whole image layer
                im_res(:,:,i) = imguidedfilter(im(:,:,i) .* map_edges, ...
                    "DegreeOfSmoothing", 0.004, "NeighborhoodSize",3) ./ W;               
            end
        end

%         function im_res = run_method_2_imlmfilt(obj)
%             im=im2double(obj.Image);
%             filter_size=obj.FilterSize;
% 
%             % preallocate memory
%             [n, m, d] = size(im);
%             im_res=zeros(n, m, d, "double");
%             all_edges = zeros(n, m, d, 'double'); % now numbers not logical values
%             all_edges_bin=zeros(n,m,d,'logical'); % to detect ones in three channels
%             % detect all edges for each image layer
%             for i=1:d
%                 % extract a layer
%                 layer = im(:,:,i);
%                 % count gradients
%                 [gmag, ~] = imgradient(layer, 'central');
%                 gmag_grayscale = mat2gray(gmag);
%                 % detect edges
%                 [T, ~]=graythresh(gmag_grayscale); % compute treshold value (Otsu algorithm)
% 
%                 gmag_grayscale_bin = gmag_grayscale;
%                 gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0;
%                 gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;
%                 all_edges_bin(:,:,i)=gmag_grayscale_bin;
% 
%                 gmag_grayscale(gmag_grayscale <= T) = 0; % if pixel value is below treshold replace it with 0
%                 gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  % (piksel-treshold)
%                 all_edges(:,:,i) = gmag_grayscale ./(1-T); %(piksel - treshold)/(1-treshold) or 0/(1-treshold)=0
%             end
% 
%             % Prepare binary map of edges
%             im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
%             im_edges_binary=additional_functions.delete_false_edges(im_edges_binary, n, m, obj.CutPoint);
%             im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));
% 
%             for i=1:d
%                 im_edges=all_edges(:,:,i).*im_edges_binary_open;
%                 map_edges = imcomplement(im_edges);
% 
%                 % make a weight map
%                 % W = imfilter(map_edges, filter_mask, 'symmetric', 'conv');
%                 W = imnlmfilt(map_edges, "DegreeOfSmoothing",0.01);
% 
%                 % filter whole image layer
%                 im_res(:,:,i) = imnlmfilt(im(:,:,i) .* map_edges,"DegreeOfSmoothing",0.01) ./ W;
%             end
%         end


        function im_res = run_method_2_imlmfilt(obj)
            im=im2double(obj.Image);
            filter_size=obj.FilterSize;

            % preallocate memory
            [n, m, d] = size(im);
            im_res=zeros(n, m, d, "double");
            W=zeros(n, m, d, "double");
            all_edges = zeros(n, m, d, 'double'); % now numbers not logical values
            all_edges_bin=zeros(n,m,d,'logical'); % to detect ones in three channels
            % detect all edges for each image layer
            for i=1:d
                % extract a layer
                layer = im(:,:,i);
                % count gradients
                [gmag, ~] = imgradient(layer, 'central');
                gmag_grayscale = mat2gray(gmag);
                % detect edges
                [T, ~]=graythresh(gmag_grayscale); % compute treshold value (Otsu algorithm)

                gmag_grayscale_bin = gmag_grayscale;
                gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0;
                gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;
                all_edges_bin(:,:,i)=gmag_grayscale_bin;

                gmag_grayscale(gmag_grayscale <= T) = 0; % if pixel value is below treshold replace it with 0
                gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  % (piksel-treshold)
                all_edges(:,:,i) = gmag_grayscale ./(1-T); %(piksel - treshold)/(1-treshold) or 0/(1-treshold)=0
            end

            % Prepare binary map of edges
            im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
            im_edges_binary=additional_functions.delete_false_edges(im_edges_binary, n, m, obj.CutPoint);
            im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));

            for i=1:d
                im_edges=all_edges(:,:,i).*im_edges_binary_open;
                map_edges = imcomplement(im_edges);

                % make a weight map
                % W = imfilter(map_edges, filter_mask, 'symmetric', 'conv');
                W(:,:,i) = imnlmfilt(map_edges, "DegreeOfSmoothing",0.01);

                % multiply img by edge-maps
                im_res(:,:,i) = im(:,:,i) .* map_edges;
            end

            
            im_res = rgb2lab(im_res);

            % Extract a homogeneous L*a*b patch from the noisy background to compute the noise standard deviation.
            roi = [210,24,52,41];
            patch = imcrop(im_res,roi);

            patchSq = patch.^2;
            edist = sqrt(sum(patchSq,3));
            patchSigma = sqrt(var(edist(:)));

            % Set the 'DegreeOfSmoothing' value to be higher than the standard deviation of the patch.
            % Filter the noisy L*a*b* image using non-local means filtering.

            DoS = 1.05*patchSigma;
           im_res = imnlmfilt(im_res,'DegreeOfSmoothing',DoS);
           im_res = lab2rgb(im_res,'Out','double');

            for i=1:d
                im_res(:,:,i) = im_res(:,:,i)/W(i);
            end
        end

        function im_res = run_method_2_median(obj)

            im=im2double(obj.Image);
            filter_size=obj.FilterSize;
          
            % preallocate memory
            [n, m, d] = size(im);
            im_res=zeros(n, m, d, "double");
            all_edges = zeros(n, m, d, 'double'); % now numbers not logical values
            all_edges_bin=zeros(n,m,d,'logical'); % to detect ones in three channels
            % detect all edges for each image layer
            for i=1:d
                % extract a layer
                layer = im(:,:,i);
                % count gradients
                [gmag, ~] = imgradient(layer, 'central');
                gmag_grayscale = mat2gray(gmag);
                % detect edges
                [T, ~]=graythresh(gmag_grayscale); % compute treshold value (Otsu algorithm)

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
            im_edges_binary=additional_functions.delete_false_edges(im_edges_binary, n, m, obj.CutPoint);
            im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));
        
            for i=1:d
                im_edges=all_edges(:,:,i).*im_edges_binary_open;
                map_edges = imcomplement(im_edges);

                % make a weight map
                W = medfilt2(map_edges,[filter_size filter_size]);

                % filter whole image layer
                im_res(:,:,i) = medfilt2(im(:,:,i) .* map_edges, ...
                    [filter_size filter_size]) ./ W;
               
            end
        end


        function im_res = run_method_2_wave(obj)

            im=im2double(obj.Image);
            filter_type=obj.FilterType;
            filter_size=obj.FilterSize;
      

            opts.wname ='db4';           % wavelet type
            opts.thr_type = 'default'; % {default} - use ddencmp function - default values for denoising or compression
            % {penalized} - Estimate the noise standard deviation from the detail coefficients at given level.
            opts.alpha = 2;              % penalization parameter
            opts.level = 5;              % decomposition level
            opts.keepapp = 0;            % Threshold approximation setting, If keepapp = 1, the approximation coefficients are not thresholded.


            % preallocate memory
            [n, m, d] = size(im);
            im_res=zeros(n, m, d, "double");
            all_edges = zeros(n, m, d, 'double');
            all_edges_bin=zeros(n,m,d,'logical'); % to detect ones in three channels
            % detect all edges for each image layer
            for i=1:d
                % extract a layer
                layer = im(:,:,i);
                % count gradients
                [gmag, ~] = imgradient(layer, 'central');
                gmag_grayscale = mat2gray(gmag);
                % detect edges
                [T, ~]=graythresh(gmag_grayscale); % compute treshold value (Otsu algorithm)

                gmag_grayscale_bin = gmag_grayscale;
                gmag_grayscale_bin(gmag_grayscale_bin <= T) = 0;
                gmag_grayscale_bin(gmag_grayscale_bin > T) = 1;
                all_edges_bin(:,:,i)=gmag_grayscale_bin;

                gmag_grayscale(gmag_grayscale <= T) = 0; % if pixel value is below treshold replace it with 0
                gmag_grayscale(gmag_grayscale > T) = gmag_grayscale(gmag_grayscale > T) - T;  % (piksel-treshold)
                all_edges(:,:,i) = gmag_grayscale ./(1-T);
            end


            filter_type=obj.FilterType;
            filter_size=obj.FilterSize;
            sigm=obj.Sigma;
            filt=filters(filter_type, filter_size, sigm);
            filter_mask=make_filter(filt);

            % Prepare binary map of edges
            im_edges_binary=logical(sum(all_edges_bin, 3) == 3);
            im_edges_binary=additional_functions.delete_false_edges(im_edges_binary, n, m, obj.CutPoint);
            im_edges_binary_open = imopen(im_edges_binary, strel('square', 2));

            for i=1:d
                im_edges=all_edges(:,:,i).*im_edges_binary_open;
                map_edges = imcomplement(im_edges);

                % make a weight map
                W = imfilter(map_edges,filter_mask, 'symmetric', 'conv');

                % filter whole image layer
                im_res(:,:,i) = wiener2(im(:,:,i) .* map_edges, ...
                    [3 3]) ./ W;

            end
        end



    end
end

