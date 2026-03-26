function [DATA_RAW, EEG_PARAMS] = Preprocess(DATA_RAW,EEG_PARAMS)

if all(DATA_RAW.SSVEP_freq ~= EEG_PARAMS.SSVEP_freq)
   warning('Wrong SSVEP Frequency!!');
   EEG_PARAMS.SSVEP_freq = DATA_RAW.SSVEP_freq;
end

dataFilt = cog_filter(DATA_RAW.data,EEG_PARAMS.filt);
DATA_RAW.data = dataFilt;

% Reject Bad Channels

if EEG_PARAMS.bad_ch_rej_flag
    
    EPOCHS_FILT = MakeEpochs(DATA_RAW,EEG_PARAMS);
    [pMaxAmp, pStdDev, pGradient] = cog_scads_1_2(permute(EPOCHS_FILT.epochs,[2,1,3]));
    rejectSensorsMA = cog_scads_1_3(pMaxAmp, 3);
    rejectSensorsSD = cog_scads_1_3(pStdDev, 3);
    rejectSensorsGD = cog_scads_1_3(pGradient, 3);
    rejectSensors = unique([rejectSensorsMA' rejectSensorsSD' rejectSensorsGD']);
    
    index = setdiff(1:length(DATA_RAW.electrodes),rejectSensors);
    goodSensors = DATA_RAW.electrodes(index);
    dataFilt = dataFilt(index,:);
    
    DATA_RAW.data = dataFilt;
    DATA_RAW.electrodes = goodSensors;
    EEG_PARAMS.electrodes = goodSensors;
    
end

if EEG_PARAMS.demean_reref_flag
    dataFilt = dataFilt - nanmean(dataFilt,2);  % Demean
    dataFilt = dataFilt - nanmean(dataFilt,1);  % Reref
end

if EEG_PARAMS.z_score_flag
    dataFilt = zscore(dataFilt')';
end

DATA_RAW.data = dataFilt;


end