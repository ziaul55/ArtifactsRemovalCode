classdef file_operations
    %FILE_OPERATIONS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        Datasets
        Filters
        Methods
        Q
    end

    methods
        function obj = file_operations(json_path)
            %READ_JSON Read data from json file
            %   json_path - filepath to json file
            %   returns datasets - struct with data
            f_handler=fopen(json_path);
            formatSpec='%s';
            raw=fscanf(f_handler,formatSpec);
            fclose(f_handler);
            data=jsondecode(raw);

            try
                obj.Datasets = data.datasets;
                obj.Filters = data.filters;
                obj.Methods = data.methods;
                obj.Q = data.q;
            catch ME
                if (strcmp(ME.identifier,''))
                    msg = 'File with parameters was invalid. Please check the file and try again.';
                    causeException = MException('MATLAB:myCode:dimensions',msg);
                    ME = addCause(ME,causeException);
                end
                rethrow(ME);
            end
        end
        
        function tune_parameters(obj)

            % Dataset
            for i=1:length(obj.Datasets)
                dataset = obj.Datasets(i);
                res_folder = dataset.results_filepath;
                path=sprintf("%s*.%s",dataset.filepath, dataset.filetype);
                im_files = dir(path);

                % Quality
                for q=1:length(obj.Q)
                    quality = string(obj.Q(q));

                    % Image
                    for idx=1:length(im_files)
                         [im_org, name] = additional_functions.load_image(im_files(idx));

                         % compress image
                         im_jpg = additional_functions.compress_image(im_org, obj.Q(q));

                         % count metrics for jpg
                         metrics_jpg = quality_metrics.count_metrics(im_jpg, im_org, 0);

                        % Filter
                        for f=1:length(obj.Filters)
                            filter = obj.Filters(f);
                            filter_type = string(filter.type);

                            % Create cell with parameters
                            params = additional_functions.create_params(filter.sigmas, filter.sizes);

                            % Method
                            for m=1:length(obj.Methods)
                                method = string(obj.Methods(m));
                                path_raw = sprintf("%s/%s/%s/%s/",res_folder,quality,method,filter_type);
                                additional_functions.create_folder(path_raw);
                                
                                compute_parallel_params(obj, params, im_org, im_jpg, metrics_jpg);

                            end
                        end
                    end
                end
            end
        end
         
        function compute_parallel_params(filter_type, params, im_org, im_jpg, metrics_jpg)
            parfor k=1:length(params)
                param=params(k,:);
                sigma=cell2mat(param(1,1));
                filter_size=cell2mat(param(1,2));
                % run algorithm
                rem = remove_artifacts(im_jpg, [1, 1], sigma,...
                    filter_size, filter_type, method);
                im=run_artifacts_removal(rem);

                % count metrics
                [im_ssim, im_psnr, im_niqe] = quality_metrics.count_metrics(im, im_org,model);
                delta_psnr = quality_metrics.count_delta(im_psnr, jpg_psnr);
                delta_ssim = quality_metrics.count_delta(im_ssim, jpg_ssim);
                delta_niqe=quality_metrics.count_delta(im_niqe, jpg_niqe);

                % save row to the table
                t_tabs_gauss{k}(end+1,:) = {name, 'gauss',method, ...
                    sigma, filter_size, jpg_psnr, im_psnr, delta_psnr, jpg_ssim,...
                    im_ssim, delta_ssim, jpg_niqe, im_niqe, delta_niqe};

                % save image to a file
                % [gauss_method_s{sigma}_f{filter_size}_name.jpg]
                img_rem_name_gauss = string(strcat(image_folder_gauss,'\',method,'\', ...
                    's_',string(sigma),'_f_',string(filter_size),name,'.png')) ;
                imwrite(im,img_rem_name_gauss,"png");
            end
        end

    end
end

