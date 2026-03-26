function [SSVEP_power] = RT_SSVEP_noDSS(ring_buffer,EEG_PARAMS,METHOD_PARAMS)

Fs = EEG_PARAMS.Fs;
Time = size(ring_buffer,2)/Fs;
SSVEP_freq = EEG_PARAMS.SSVEP_freq;
params = EEG_PARAMS.params;

buff_filt = RT_Preprocess(ring_buffer,EEG_PARAMS);
SSVEP_power=[];
for lr = 1:2
    params.fpass = SSVEP_freq(lr);
    SSVEP_power = [SSVEP_power mtspectrumc(buff_filt',params)/Time];
end

SSVEP_power = abs(SSVEP_power);

end