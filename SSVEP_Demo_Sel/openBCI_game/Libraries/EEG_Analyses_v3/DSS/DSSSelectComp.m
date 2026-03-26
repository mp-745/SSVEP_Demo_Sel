function CompNo = DSSSelectComp(data, pnq, AT_idx, AA_idx, SSVEP_freq, EEG_PARAMS)

w=zeros(128,128);
w(EEG_PARAMS.electrodes,1:size(pnq,2)) = pnq;
w_inv = zeros(128,128);
w_inv(EEG_PARAMS.electrodes,1:size(pnq,2)) = pinv(pnq)';

for comp = 1:size(data,1)
    fig = figure;
    set(fig,'Position',[0 0 1920 1080]);
    W{1} = w(:,comp); W{2} = w_inv(:,comp);
    PlotComp(squeeze(data(comp,:,:)), W, AT_idx, AA_idx, SSVEP_freq, [1 1], EEG_PARAMS);
    suptitle(sprintf('DSS comp %d at %d',comp,SSVEP_freq)); 
end

CompNo = input('Enter Component No: ');

end