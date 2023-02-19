classdef additional_functions
    %ADDITIONAL_FUNCTIONS Other functions used during processing images

    methods (Static)
        function true_edges = delete_false_edges(im, n, m, cut_point)
            %DELETE_FALSE_EDGES function to detect jpg compression grid
            % copies the real edges and removes false edges from the image
            % for binary images it returns 2d logical array
            % for double images it returns 2d double array
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

        function compress_files(im_path, res_path, Q)
            %COMPRESS_FILES Function to compress files with jpeg algorithm.
            % im_path - folder with files to compress
            % res_path - folder with results (must be different than im_path)
            % Q - vector of compression quality parameters

            im_files = dir(im_path);

            % set a path for result images
            images_folder = strcat(res_path,'\Q');

            for i=1:length(Q)
                % Check if folder exists, if not create it
                images_folder_q=strcat(images_folder,string(Q(i)));

                if isfolder(images_folder_q) == false
                    mkdir(images_folder_q);
                end

                for ind=3:length(im_files)
                    % read an image and convert it into uint8
                    im_name = strsplit(im_files(ind).name, '.');
                    f_name = [im_files(ind).folder '\' im_files(ind).name];
                    im = imread(f_name);

                    % convert to uint8
                    im_org = additional_functions.conv_to_uint8(im);

                    % set image name
                    res_name=strcat(images_folder_q,'\',im_name(1),'.jpg');

                    % compress to jpg with quality Q
                    imwrite(im_org, res_name, 'jpg', 'Quality', Q(i));
                end
            end
        end

        function perform_segmentation(im_path, res_filepath)
            %PERFORM_SEGMENTATION Function  to perform segmentation
            %   filepath - directory with images to segment
            %   res_filepath - directory for results
            im_files = dir(im_path);

            for ind=3:length(im_files)
                im_name = strsplit(im_files(ind).name, '.');
                name=string(im_name(1));
                f_name = [im_files(ind).folder '\' im_files(ind).name];
                he = imread(f_name);
                lab_he = rgb2lab(he);;
                ab = lab_he(:,:,2:3);
                ab = im2single(ab);
                numColors = 3;
                L2 = imsegkmeans(ab,numColors);
                B2 = labeloverlay(he,L2);
                imshow(B2);
                res_filename=strcat(res_filepath,name,'_segm.png');
                imwrite(B2,res_filename);
            end
        end

        function test_algorithm(method, sigma, filter_size, filter_type, quality)
            %TEST_ALGORITHM Function to test algorithms on selected image
            %   method - chosen method
            %   filter_size - size of filter kernel
            %   filter_type - type of filter
            %   quality - compression quality parameter
            %   siqma - sigma for Gaussian filter

            % read an .tif image an convert it to uint8
            [im_file, im_path] = uigetfile({'*.tif' ; '*.tiff'}, 'Select an image');
            im_org_uint16 = imread([im_path '\' im_file]);
            im_org = additional_functions.conv_to_uint8(im_org_uint16);

            % compress to jpg
            imwrite(im_org, 'jpg_conv.jpg', 'jpg', 'Quality', quality);
            im_jpg= imread('jpg_conv.jpg');

            rem = remove_artifacts(im_jpg, [1 1], sigma,...
                filter_size,filter_type, method);

            im=run_artifacts_removal(rem);

            rect=[100 100 200 200];
            crop_im=imcrop(im, rect);
            crop_org=imcrop(im_org, rect);
            crop_jpg=imcrop(im_jpg, rect);
            montage({crop_org, crop_jpg, crop_im}, "Size",[1 3]);
                title("Original                      Compressed                 Processed");
        end

        function auto_removal(im_dir, q, res_dir)
            % AUTO_REMOVAL - removes artifacts from jpg images,
            % sigma is based on q parameter
            % im_dir - directory with .jpg images
            % q - compression quality parameter
            % res_dir - directory to save result files
            im_files = dir(strcat(im_dir,"*.jpg"));
            
            a=21.68;
            b=0.6652;
            c=6.01;
            d=-4.186;

            sigma=c+(b-c)/(1+(q/a)^d);

            for ind=1:length(im_files)
                % read an image and convert it into uint8
                im_name = strsplit(im_files(ind).name, '.');
                name=string(im_name(1));
                f_name = [im_files(ind).folder '\' im_files(ind).name];
                im_jpg = imread(f_name);

                rem = remove_artifacts(im_jpg, [1 1], sigma,...
                    3, 'gauss', 'method_2');
                im=run_artifacts_removal(rem);

                %save image
                imwrite(im, strcat(res_dir,name,'processed.png'), 'png');
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
                case 'tiff'
                    im_org = additional_functions.load_tiff(file);
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
        end

        function im_org = load_tiff(im_file)
            f_name = [im_file.folder '\' im_file.name];
            im = imread(f_name);
            im_org = additional_functions.conv_to_uint8(im);
            disp("tiff");
        end

        function im_org = load_bmp(im_file)
            f_name = [im_file.folder '\' im_file.name];
            im = imread(f_name);
            im_org = additional_functions.conv_to_uint8(im);
            disp("bmp");
        end

        function im_org = load_png(im_file)
            f_name = [im_file.folder '\' im_file.name];
            im = imread(f_name);
            im_org = additional_functions.conv_to_uint8(im);
            disp("png");
        end

        function im_org = load_jpg(im_file)
            f_name = [im_file.folder '\' im_file.name];
            im = imread(f_name);
            im_org = additional_functions.conv_to_uint8(im);
            disp("jpg");
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
                        causeException = MException('MATLAB:myCode:dimensions',msg);
                        ME = addCause(ME,causeException);
                    end
                    rethrow(ME);
                end
            end
        end

    end
end

