function out_struct = InitEEG(subject_no)

%% Basic EEG
channels = 41;
electrodes = 1:channels;
Fs = 4096;
downsample_factor = 32; Fs = Fs/downsample_factor;

%% Flags

demean_reref_flag = true;
z_score_flag = true; 
bad_ch_rej_flag = true;
filt_type = 'bpfilt';

%% Params for mtspectrum

params = struct();
params.Fs = Fs;
params.tapers = [1 1];
params.pad = -1;
params.err = 0;
params.trialave = 0;

%% Filter

if strcmp(filt_type,'bpfilt')
    filt = designfilt('bandpassfir', 'StopbandFrequency1', 2, 'PassbandFrequency1', 12, 'PassbandFrequency2', 20, 'StopbandFrequency2', 43, 'StopbandAttenuation1', 30, 'PassbandRipple', 1, 'StopbandAttenuation2', 30, 'SampleRate', Fs);
elseif strcmp(filt_type,'DelayLine')
    filt = round(Fs/50);
end

%% Triggers

trig.start = 20;
trig.stop = 30;

%% SSVEP Freq

SSVEP_freq = [15,15];

Noise_freq = [11 17];

%% Make struct

vars  = who;

for i = 1:length(vars)
    out_struct.(vars{i}) =  eval(vars{i});
end

end