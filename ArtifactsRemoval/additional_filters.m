
img = imread("../Case_1-04.tif");
opts.filt_type = '';

switch opts.filt_type
    case 'none'
        data_filt = data_filt;
    case '2DMF'
        data_filt = filt_match2D(data_filt,opts);
    case 'L2DMF'
        data_filt = filt_lmatch2D(data_filt,opts);
    case 'MedF'
        data_filt = medfilt2(data_filt,[opts.mask,opts.mask]);
    case 'WF'
        data_filt = wiener2(data_filt,[opts.mask,opts.mask]);
    case 'MMWF'
        [~,~,~,~,data_filt] = MMWF_2D_website(data_filt,opts.mask);
    case 'Wave'
        data_filt = filt_wave(data_filt,opts);
    case 'DPMF'
        data_filt = DoublePassMatchedFilter(data_filt,opts.mask,opts.std_v,opts.std_h,max(data_filt(:)),max(data_filt(:)));
    case 'CT'
        %data_filt = filt_CT(data_filt,opts);
        data_filt = fcn_hsnsctshrink(double(data),{'maxflat','dmaxflat5'},opts.nlevs,2.^(-length(opts.nlevs)+1:1:0));
        data_filt = max(data_filt,0);
    otherwise
        error('Wrong filtering method.')
end