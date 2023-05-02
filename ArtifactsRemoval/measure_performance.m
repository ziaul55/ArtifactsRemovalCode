% script to measure time and memory usage

% *gpu and parallel pool
%  it is possible to use both gpu and parallel pool. 
%  more information here:
%  https://www.mathworks.com/matlabcentral/answers/1633900-can-i-use-my-cpu-and-gpu-simultaneously-for-numerical-simulation
%  https://www.mathworks.com/matlabcentral/answers/369501-how-are-gpuarrays-handled-inside-parfor
%  method2_WSI can use gpuArrays instead of normal arrays.


% parameters
filepath ="..\Datasets\TCGA.svs"; % path to the svg file
output = "..\output\";            % path to the output for binary files
blocksize =[2048 2048];           % size of the block (if the cutpoint of the image is [1 1] size of the block should be the multiple of 8)
parallel = true;                  % use parallel pool 
filt_size = 3;                    % size of the filter
sigma = 1.1;                      % std of the gaussian filter
res_path = "result.svs";          % path for the results
gpu=true;                         % use gpu or not 

% parpool params
numberOfWorkers = 3;
pool = parpool(numberOfWorkers);

% measure time
tic
load_wsi_func(filepath, output, blocksize, parallel, filt_size, sigma, res_path, gpu); % handle to function
toc