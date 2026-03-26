function [data_out,data_out_mean] = DSSEstComp(data_in, pnq, Comps)

data_in = permute(data_in, [2,1,3]);
data_out = nt_mmat(data_in, pnq(:,Comps));

data_out = permute(data_out, [2,1,3]);
data_out_mean = nanmean(data_out, 3);

end