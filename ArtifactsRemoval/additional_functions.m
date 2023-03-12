classdef additional_functions
    %ADDITIONAL_FUNCTIONS Other functions used during processing images


    methods (Static)
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

        function converted = conv_to_uint8(im)
            %CONV_TO_UINT8 function to convert an image to uint8 image
            % TIFF file is loaded as uint16 file but BreCaHAD dataset 
            % should be stored as uint8 images
            % im - image
            im = double(im);
            converted = uint8(im ./ max(max(im)) * 255);
        end

        function params = create_params(sigmas, filter_sizes)
            %CREATE_PARAMS creates params cell
            %sigmas - vector of sigma values
            %filter_sizes - vector of filter sizes
            params=cell(length(sigmas)*length(filter_sizes),2);
            k=0;
            for i=0:length(params)-1
                if(mod(i,length(sigmas))==0)
                    k=k+1;
                end
                params{i+1,1}=sigmas(mod(i,length(sigmas))+1);
                params{i+1,2}=filter_sizes(k);
            end
        end

        function jpg = compress_image(image, q)
            %READ_IMAGE
            % Function to load the image
            % image - image to compress 
            % q - quality factor (0-100)
            % returns jpq - compressed image
            imwrite(image, 'jpg_conv.jpg', 'jpg', 'Quality', q);
            jpg = imread('jpg_conv.jpg');
            delete('jpg_conv.jpg');
        end

        function [im_org, name] = load_image(file)

            split_name = strsplit(file.name, '.');
            type = string(split_name(2));
            name=string(split_name(1));

            switch type
                case 'tif'
                    im_org = additional_functions.load_tif(file);
                case 'png'
                    im_org = additional_functions.load_png(file);
                case 'bmp'
                    im_org = additional_functions.load_bmp(file);
                case 'jpg'
                    im_org = additional_functions.load_jpg(file);
                otherwise
                    ME=MException('Unknown filetype', '%s files are not supported', type);
                    throw(ME);
            end

            if isa(im_org,'uint8') == false
                im_org = additional_functions.conv_to_uint8(im_org);
            end
        end

        function tab = load_csv(file)
            f_name = [file.folder '/' file.name];
            tab = readtable(f_name);
        end

        function im_org = load_tif(im_file)
            f_name = [im_file.folder '/' im_file.name];
            im_org = imread(f_name);
            
        end

        function im_org = load_bmp(im_file)
            f_name = [im_file.folder '/' im_file.name];
            im_org = imread(f_name);
            
        end

        function im_org = load_png(im_file)
            f_name = [im_file.folder '/' im_file.name];
            im_org = imread(f_name);
           
        end

        function im_org = load_jpg(im_file)
            f_name = [im_file.folder '/' im_file.name];
            im_org = imread(f_name);
            
        end

        function create_folder(path)
            %CREATE_FOLDERS
            % Function to create folder if it does not exist.
            % path - filepath of the folder
            if isfolder(path) == false
                try
                    mkdir(path);
                catch ME
                    if (strcmp(ME.identifier,''))
                        msg = sprintf("Folder creation failed. Path: %s",path);
                        causeException = MException('MyComponent:fileException',msg);
                        ME = addCause(ME,causeException);
                    end
                    rethrow(ME);
                end
            end
        end

        function save_image(img, path, type)
            imwrite(img,path,type);
        end

    end
end

