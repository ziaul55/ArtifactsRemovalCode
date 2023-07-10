function results_table = process_dataset(dataset, method, opts)
%PROCESS_DATASET function to process dataset
% dataset - structure with information about the dataset
% - result - path for the result files
% - Q - quality compression factors vector
% - filepath - path to the folder with the images
% - save_jpg - save jpg images or not
% - save - save processed images or not
% opts - structure with parameters for the method
% method - the name of the method
% returns result_table - table with results

results_table = table();
% read dataset
path=sprintf("%s*.%s",dataset.filepath, dataset.filetype);
im_files = dir(path);

% create param combinations for data processing
params = create_params(opts);

for q = 1:length(dataset.Q)
    for idx=1:length(im_files)

        % read file
        [im_org, name] = load_image(im_files(idx));

        % compress file
        im_jpg = compress_image(im_org,dataset.Q(q));

        % calculate ssim and psnr
        [ssim_jpg, psnr_jpg] = calculate_metrics(im_jpg, im_org);

        Q=dataset.Q(q);
        file_results_table = table();

        % process jpg with chosen method
        parfor p = 1:length(params)
            im = process_image(im_jpg,params{p}, method,false);

            % calculate ssim and psnr
            [ssim, psnr] = calculate_metrics(im, im_org);

            % save results to the table
            params_table = struct2table(params{p});
            new_row = table(name, ssim, psnr, ssim_jpg, psnr_jpg,Q, method,params_table);
            new_row = splitvars(new_row);
            file_results_table = [file_results_table; new_row];
        end
        
        results_table = [results_table; file_results_table];
    end
end

% save table
csv_path = sprintf("%s/raw.csv",dataset.result);
writetable(results_table, csv_path );
end

