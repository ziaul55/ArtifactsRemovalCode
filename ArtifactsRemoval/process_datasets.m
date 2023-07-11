dataset.filepath = "C:\Users\Julia\Documents\GitHub\ArtifactsRemovalCode\Datasets\BreCaHAD\";
dataset.result = "C:\Users\Julia\Documents\GitHub\ArtifactsRemovalCode\Datasets\Quick\";
dataset.filetype = "tif";
dataset.save = true;
dataset.save_jpg = true;
dataset.Q = [10,20,30];

opts.Sigma = [1.4];
opts.Size = [3];
opts.CutPoint = {[1 1]};
methods(1).name = "EPA_ID_gauss";
methods(1).opts = opts;

tab = process_dataset(dataset(1), methods(1).name, methods(1).opts);
[res_psnr, res_ssim] = calculate_stats(tab);