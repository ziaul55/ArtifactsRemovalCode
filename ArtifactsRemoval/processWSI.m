% WSI with EPA_ID processing example

opts.Sigma = 1.7;
opts.Size = 3;
opts.Gpu = false;
blocksize = [1024 1024];
parallel = true;
res_path="new.svs";
filepath = "Images/TCGA.svs";
processWSI(filepath, blocksize, parallel, res_path, opts);