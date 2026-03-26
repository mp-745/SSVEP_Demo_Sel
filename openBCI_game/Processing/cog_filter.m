function [dataFilt] = cog_filter(data,filt)

if isobject(filt)
    dataFilt = filtfilt(filt,data')';
else
    dataFilt = data(:,filt+1:end) - data(:,1:end-filt);
end

end