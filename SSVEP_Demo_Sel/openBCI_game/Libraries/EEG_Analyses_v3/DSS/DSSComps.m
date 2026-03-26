function DSS_PARAMS = DSSComps(EPOCHS,EEG_PARAMS,SAVE)

pnq = [];
SSVEP_freq = EEG_PARAMS.SSVEP_freq;
Fs = EEG_PARAMS.Fs;
epochs = EPOCHS.epochs;

fig = figure;
set(fig,'Position',[0 0 1920 1080]);
LR = {'Left','Right'};

for lr = 1:length(LR)
    
    if lr==1
       AT_idx = EPOCHS.LeftFlick_T_idx; AA_idx = EPOCHS.LeftFlick_D_idx; 
    else
       AT_idx = EPOCHS.RightFlick_T_idx; AA_idx = EPOCHS.RightFlick_D_idx; 
    end
    
    pnq{lr} = DSSGetPnq(epochs(:,:,[AT_idx,AA_idx]), SSVEP_freq(lr), Fs);
    dss_out = DSSEstComp(epochs, pnq{lr}, 1:5);
    w=zeros(128,128);
    w(EEG_PARAMS.electrodes,1:size(pnq{lr},2)) = pnq{lr};
    w_inv = zeros(128,128);
    w_inv(EEG_PARAMS.electrodes,1:size(pnq{lr},2)) = pinv(pnq{lr})';
    
    CompNo(lr) = DSSSelectComp(dss_out, pnq{lr}, AT_idx, AA_idx, SSVEP_freq(lr), EEG_PARAMS);
    figure(fig);
    W{1} = w(:,CompNo(lr)); W{2} = w_inv(:,CompNo(lr));
    PlotComp(squeeze(dss_out(CompNo(lr),:,:)), W, AT_idx, AA_idx, SSVEP_freq(lr), [length(LR) lr], EEG_PARAMS,'title_str',LR{lr});
    DSS_PARAMS.pnq{lr} = pnq{lr}(:,CompNo(lr));
    
end

DSS_PARAMS.method = 'DSS';    
saveas(fig,[SAVE.savepath sprintf('DSS_Comp_%s.png',SAVE.fname)]);   

end