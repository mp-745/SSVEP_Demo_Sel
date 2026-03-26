for i=1:size(epochs,3)
    datTrain(i).trialId = i;
    datTrain(i).spikes = epochs(:,:,i);
end

xDim = length(kernels);
binWidth = 1;
kernSD = 1;
emiters = 500;
smallsig = 10^-5;

extraOpts = {'kernSDList', kernSD, 'useSqrt', false,'emMaxIters', emiters,'segLength',20,'normalize_c',false};

seqTrain  = getSeq(datTrain, binWidth, extraOpts{:});
temp = struct();
seqTest = temp([]);