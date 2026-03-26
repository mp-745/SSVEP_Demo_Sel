function pnq_out = SelectComp(data,pnq_in,freq,EEG_PARAMS)

Fs = EEG_PARAMS.Fs;
Time = size(data,2)/Fs;
params = EEG_PARAMS.params;

params.fpass = freq;
SSVEP_power = mtspectrumc(data',params)/Time;

params.fpass = [5 12];
Noise_power1 = mtspectrumc(data',params)/Time;
params.fpass = [20 30];
Noise_power2 = mtspectrumc(data',params)/Time;

SNR = SSVEP_power./(sum([Noise_power1;Noise_power2],1));

% [~,idx] = max(SNR);
[~,temp]=sort(SNR);
idx=temp(end-size(data,1)+1:end);
pnq_out = pnq_in(:,idx);

end
