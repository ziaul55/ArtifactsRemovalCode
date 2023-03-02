classdef quality_metrics
    %QUALITY_METRICS Static class used to calculate quality metrics and
    % percentage difference of results for image before and after artifacts
    % removal
    methods (Static)
        %COUNT_METRICS function to count image quality metrics
        % im - processed image or jpg
        % im_org - original TIFF file
        % model - NIQE model
        function [im_ssim, im_psnr, im_niqe] = count_metrics(im, im_org, train, model)
            [ssimVal, ~]=ssim(im, im_org,"DataFormat","SSC");
            im_ssim=mean(ssimVal,"all");
            im_psnr=psnr(im, im_org);

            if train
                 im_niqe=niqe(im, model);
            else
                im_niqe=niqe(im);
            end
        end

        %COUNT_DELTA function to count percentage difference between
        % quality metrics for jpg image and image after artifacts removal
        % im_mertric - metric value for processed image
        % im_jpg - metric value for jpg image
        function delta = count_delta(im_metric, jpg_metric)
            delta=(im_metric - jpg_metric) / jpg_metric * 100;
        end
        
        %TRAIN_NIQE function to create NIQE model 
        % filepath - path to a directory with TIFF images
        % extension - file extension
        function model = train_niqe(filepath, extenstion)
            setDir = fullfile(filepath);
            extension = sprintf('.%s', extenstion);
            imds = imageDatastore(setDir,'FileExtensions',{extension});
            model = fitniqe(imds);
        end
    end
end

