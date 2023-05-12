classdef tune_parameters
    %FILE_OPERATIONS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        Datasets 
        Filters 
        Methods 
        Q 
        TabPattern
    end

    methods
        function obj = tune_parameters(json_path)
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
                    causeException = MException('MyComponent:InvalidParameters',msg);
                    ME = addCause(ME,causeException);
                end
                rethrow(ME);
            end
        end

        function obj=prepare_tabels(obj)

            % make a tables for the results
            % gaussian filter
            t_size = {'Size' [0 12]};
            t_vars = {'VariableTypes', ["string","string", "string", "string", "double", ...
                "double", "double", "double", "double","double","double","double"]};

            t_names = {'VariableNames', ["quality","name", "type", "method", "sigma", ...
                "filter_size", "jpg_PSNR", "PSNR", "delta_PSNR","jpg_SSIM","SSIM",...
                "delta_SSIM"]};

            obj.TabPattern = table(t_size{:}, t_vars{:}, t_names{:});
        end

        function process_images(obj)
            % Dataset
            for i=1:length(obj.Datasets)
                dataset = obj.Datasets(i);
                res_folder = dataset.results_filepath;

                path_benchmarks = sprintf("%s/benchmarks/",res_folder);
                additional_functions.create_folder(path_benchmarks);

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
                        [jpg_ssim, jpg_psnr] = quality_metrics.count_metrics(im_jpg, im_org);


                        % Filter
                        for f=1:length(obj.Filters)
                            filter = obj.Filters(f);
                            filter_type = string(filter.type);

                            % Create cell with parameters
                            params = additional_functions.create_params(filter.sigmas, filter.sizes);

                            % Method
                            for m=1:length(obj.Methods)
                                method = string(obj.Methods(m));

                                path_raw = sprintf("%s/%s/%s/%s/raw/",res_folder,quality,method,filter_type);
                                additional_functions.create_folder(path_raw);

                                path_means = sprintf("%s/%s/%s/%s/means/",res_folder,quality,method,filter_type);
                                additional_functions.create_folder(path_means);

                                path_heatmaps = sprintf("%s/%s/%s/%s/heatmaps/",res_folder,quality,method,filter_type);
                                additional_functions.create_folder(path_heatmaps);

                                % Create folder for images
                                path_images="";

                                if dataset.save
                                    path_images = sprintf("%s/%s/%s/%s/images/",res_folder,...
                                        quality,method,filter_type);
                                    additional_functions.create_folder(path_images);
                                end

                                obj = compute_parallel_params(obj,filter_type, params, im_org, im_jpg,...
                                    jpg_psnr, jpg_ssim, method, name, path_images, path_raw,dataset.filetype, quality,dataset.save);

                            end
                        end
                    end
                end
            end
        end

        function obj = compute_parallel_params(obj,filter_type, params, im_org, im_jpg,...
                jpg_psnr, jpg_ssim, method, name, path_images,path_raw, type, quality,save_file)

            t_tabs=cell(length(params),1);
            for t=1:length(params)
                t_tabs{t}=obj.TabPattern;
            end

            parfor k=1:length(params)
                param=params(k,:);
                sigma=cell2mat(param(1,1));
                filter_size=cell2mat(param(1,2));
                % run algorithm
                rem = remove_artifacts(im_jpg, [1, 1], sigma,...
                    filter_size, filter_type, method);
                im=run_artifacts_removal(rem);

                % count metrics
                [im_ssim, im_psnr] = quality_metrics.count_metrics(im, im_org);
                delta_psnr = quality_metrics.count_delta(im_psnr, jpg_psnr);
                delta_ssim = quality_metrics.count_delta(im_ssim, jpg_ssim);

                % save row to the table
                t_tabs{k}(end+1,:) = {quality, name, filter_type,method, ...
                    sigma, filter_size, jpg_psnr, im_psnr, delta_psnr, jpg_ssim,...
                    im_ssim, delta_ssim};

                % save image to a file if save is true
                if save_file
                    filepath = sprintf("%ssigm%0.1f_fsize%1.0f_%s.%s",path_images, sigma,filter_size, name, type);
                    additional_functions.save_image(im, filepath, type)
                end
            end

            for idx=1:length(params)
                param=params(idx,:);
                tab_path = sprintf("%ssigma_%.1ff_size%1.0f_%s.csv",path_raw, string(param(1,1)),string(param(1,2)), filter_type);
                writetable(t_tabs{idx},tab_path,"WriteMode","append");
            end
        end

       
        function process_results(obj)

            % Dataset
            for i=1:length(obj.Datasets)
                dataset = obj.Datasets(i);
                res_folder = dataset.results_filepath;

                % Quality
                for q=1:length(obj.Q)
                    quality = string(obj.Q(q));

                    % Filter
                    for f=1:length(obj.Filters)
                        filter = obj.Filters(f);
                        filter_type = string(filter.type);

                        % Method
                        for m=1:length(obj.Methods)
                            method = string(obj.Methods(m));

                            path_raw = sprintf("%s/%s/%s/%s/raw/",res_folder,quality,method,filter_type);
                            path_means = sprintf("%s/%s/%s/%s/means/",res_folder,quality,method,filter_type);
                            path_heatmaps = sprintf("%s/%s/%s/%s/heatmaps/",res_folder,quality,method,filter_type);

                            count_means(path_raw, path_means, obj);
                            create_heatmaps(path_means, path_heatmaps, method, filter_type, obj);
                            make_benchmark(path_means, res_folder, quality, obj);
                        end
                    end
                end
            end
        end

        
        function count_means(path_raw, path_means, obj)

            raw = dir(sprintf("%s*.csv",path_raw));

            % loop over tables with results - count means
            for idx=1:length(raw)
                tab=additional_functions.load_csv(raw(idx));
                tabstats = grpstats(tab,["quality","sigma", "filter_size","method","type"], "mean", ...
                    "DataVars",["PSNR","SSIM","jpg_PSNR","jpg_SSIM","delta_PSNR","delta_SSIM"]);
                tabstats=removevars(tabstats,{'GroupCount' });
                tab_path = sprintf("%smean.csv",path_means);
                writetable(tabstats,tab_path,"WriteMode", "append");
            end
        end

        function create_heatmaps(path_means, path_heatmaps, method, filter_type,obj)

            heatmap_vars=["mean_delta_PSNR",...
                "mean_delta_SSIM","mean_PSNR", "mean_SSIM"];
            titles=["Mean of delta PSNR",...
                "Mean of delta SSIM", "Mean of PSNR", "Mean of SSIM"];

            tab_path = sprintf("%smean.csv",path_means);
            tab=readtable(tab_path);

            for j=1:length(heatmap_vars)
                column_name=heatmap_vars(j);
                title=titles(j);
                h=heatmap(tab,"filter_size","sigma", ColorVariable=column_name, Title=title, XLabel="Filter size", YLabel="\sigma",FontSize=15);
                heatmap_path = sprintf("%s/%s_%s_%s_heatmap.png",path_heatmaps, method, filter_type,title);
                saveas(h,strcat(heatmap_path));
            end
        end

        function make_benchmark(path_means, res_folder, quality,obj)
            tab_path = sprintf("%smean.csv",path_means);
            tab=readtable(tab_path); 

            vars=["mean_delta_PSNR",...
                "mean_delta_SSIM","mean_PSNR","mean_SSIM"];
            
            for i=1:length(vars)
                path_benchmarks = sprintf("%s/benchmarks/%s/",res_folder, vars(i));
                additional_functions.create_folder(path_benchmarks);
                benchmark_path = sprintf("%sbenchmark.csv", path_benchmarks);
                tab_row = sortrows(tab, vars(i), "descend");
                tab_row = tab_row(1,:); 
                writetable(tab_row, benchmark_path,"WriteMode","append");
            end
        end

        function make_benchmark_heatmaps(obj)
            vars=["mean_delta_PSNR",...
                "mean_delta_SSIM", "mean_PSNR","mean_SSIM"];

            
            titles=["Mean of delta PSNR",...
                "Mean of delta SSIM", "Mean of PSNR", "Mean of SSIM"];

            for i=1:length(obj.Datasets)
                dataset = obj.Datasets(i);
                res_folder = dataset.results_filepath;

                for j=1:length(vars)
                    path_benchmarks = sprintf("%s/benchmarks/%s/",res_folder, vars(j));
                    benchmark_path = sprintf("%sbenchmark.csv", path_benchmarks);
                    tab = readtable(benchmark_path);
                    column_name=vars(j);
                    title=titles(j);
                    h=heatmap(tab,"quality","method", ColorVariable=column_name, Title=title, XLabel="quality", YLabel="method",FontSize=15);
                    h.Colormap=jet;
                    heatmap_path = sprintf("%sheatmap.png",path_benchmarks);
                    saveas(h,strcat(heatmap_path));
                end
            end
        end

        function run(obj)
            % obj=prepare_tabels(obj);
            % process_images(obj);
            process_results(obj);
            make_benchmark_heatmaps(obj);
        end

    end
end