function dataFilt = cog_scads_1_1(data, samplingRate, fL, fH, filterOrder)
    bpFilt = designfilt('bandpassfir', 'FilterOrder', filterOrder, 'CutoffFrequency1', fL,...
        'CutoffFrequency2', fH, 'SampleRate', samplingRate);
    dataFilt = zeros(size(data));
%     tic
    for i = 1:size(data,2)
%         disp(i);
        temp = squeeze(data(:,i,:));
        dataFilt(:,i,:) = filtfilt(bpFilt, double(temp));
    end
%     toc
end