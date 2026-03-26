function [dataFilt] = RT_Preprocess(data,EEG_PARAMS)

dataFilt = cog_filter(data(:,:),EEG_PARAMS.filt);

if EEG_PARAMS.demean_reref_flag
    dataFilt = dataFilt - nanmean(dataFilt,2);  % Demean
    dataFilt = dataFilt - nanmean(dataFilt,1);  % Reref
end

if EEG_PARAMS.z_score_flag
    dataFilt = zscore(dataFilt')';
end

end