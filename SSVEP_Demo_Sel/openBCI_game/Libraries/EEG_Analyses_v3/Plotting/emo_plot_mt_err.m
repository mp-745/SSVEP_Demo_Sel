function [s,f] = emo_plot_mt_err( arr,Fs,fpass )

%   data in ch X samples X trials
params.Fs = Fs;
if nargin <3
    params.fpass = [2 45];
else
    params.fpass = fpass;
end
params.tapers = [1 1];
params.pad = -1;


[s,f] = mtspectrumc(arr',params);
boundedline(f,nanmedian(s,2)',nanstd(s,[],2)'/sqrt(size(s,2)));

end