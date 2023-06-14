img_deflate=imread('Deflate.svs','Index',1,'PixelRegion', {[1,8000],[1,8000]});
img_LZW=imread('LZW.svs','Index',1,'PixelRegion', {[1,8000],[1,8000]});


img_none_after_removal=imread('None.svs','Index',1,'PixelRegion', {[1,8000],[1,8000]});
img_org_jpg=imread('org_7layers.svs','Index',1,'PixelRegion', {[1,8000],[1,8000]});
[ssim_jpeg, psnr_jpeg] = quality_metrics.count_metrics(img_deflate, img_none_after_removal);


img_packbits=imread('Packbits.svs','Index',1,'PixelRegion', {[1,8000],[1,8000]});

