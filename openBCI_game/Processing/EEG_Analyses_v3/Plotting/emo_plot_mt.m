function [s,f] = emo_plot_mt( arr,Fs,fpass )

%   data in ch X samples X trials
params.Fs = Fs;
if nargin <3
    params.fpass = [2 45];
else
    params.fpass = fpass;
end
params.tapers = [1 1];
params.pad = -1;


if ndims(arr)<=2
    [s,f] = mtspectrumc(arr',params);
    plot(f,s);
else
    for i=1:size(arr,3)
        temp = squeeze(arr(:,:,i));
        [s(:,:,i),f] = mtspectrumc(temp',params);
    end
    plot(f,mean(s,3));
end

end