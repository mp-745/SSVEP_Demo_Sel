function GPFA_PARAMS = GPFAComps(EPOCHS,EEG_PARAMS,RT_PARAMS,SAVE,varargin)

cosine_params = [EEG_PARAMS.SSVEP_freq, EEG_PARAMS.Noise_freq];
band_params = [];
uniform_params = [];
gauss = input('Enter No of Gauss: ');

assignopts(who,varargin{:});

SSVEP_freq = EEG_PARAMS.SSVEP_freq;
Fs = EEG_PARAMS.Fs;
epochs = EPOCHS.epochs;

kernels = GPFAGetKernels(Fs, cosine_params, band_params, uniform_params, gauss);

GPFAInit;

GPFAresult = gpfaEngine(seqTrain, seqTest, kernels, ...
    'xDim', xDim, 'binWidth', binWidth, extraOpts{:});

seq = GPFAresult.seqTrain;
[temp, ~] = exactInferenceWithLL(seq, GPFAresult.estParams,'getLL',false);
GPFA_out = cat(3,temp(:).xsm);

C = GPFAresult.estParams.C;
[GPFA_out, C_norm, C_factor] = cog_GPFA_normalize(GPFA_out,C);

w = zeros(128,xDim);
w(EEG_PARAMS.electrodes,:) = C_norm;
w_inv = zeros(128,xDim);
w_inv(EEG_PARAMS.electrodes,:) = pinv(C_norm)';

GPFA_plot(GPFA_out,Fs,w,w_inv,kernels);

fig = figure;
set(fig,'Position',[0 0 1920 1080]);
for fr = 1:length(SSVEP_freq)
    if fr == 1
        AT_idx = EPOCHS.Left_idx; AA_idx = EPOCHS.Right_idx; 
    else
        AT_idx = EPOCHS.Right_idx; AA_idx = EPOCHS.Left_idx;
    end
    W{1} = w(:,fr); W{2} = w_inv(:,fr);
    PlotComp(squeeze(GPFA_out(fr,:,:)), W, AT_idx, AA_idx, SSVEP_freq(fr), [2 fr], EEG_PARAMS);
end

saveas(fig,[SAVE.savepath sprintf('GPFA_Comp_%s.png',SAVE.fname)]);   

[CRinv,blkProd,xDim,T,d] = cog_getGPFAterms(GPFAresult.estParams,RT_PARAMS.ring_buffer_size,1:2);

GPFA_PARAMS.method = 'GPFA';
GPFA_PARAMS.GPFAresult = GPFAresult;
GPFA_PARAMS.C_factor = C_factor;
GPFA_PARAMS.RT.CRinv = CRinv;
GPFA_PARAMS.RT.blkProd = blkProd;
GPFA_PARAMS.RT.xDim = xDim;
GPFA_PARAMS.RT.T = T;
GPFA_PARAMS.RT.d = d;

end