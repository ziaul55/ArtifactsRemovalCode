function [mse_val] = calculate_partial_MSE(block, block_ref)
%CALCULATE_MSE function used to calculate the part of the mse of one block
mse_val = immse(block, block_ref);
mse_val = mse_val * ((size(block,1)*size(block,2)));

end

