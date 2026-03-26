titleL = sprintf('Attend Left (%dHz)', EEG_PARAMS.SSVEP_freq(1));
titleR = sprintf('Attend Right (%dHz)', EEG_PARAMS.SSVEP_freq(2));

tempL = mean(RT_Data{1},3);
tempR = mean(RT_Data{2},3);

tempL_ = RT_Preprocess(tempL, EEG_PARAMS);
tempR_ = RT_Preprocess(tempR, EEG_PARAMS);

[pL, fL] = mtspectrumc(tempL_', EEG_PARAMS.params);
[pR, fR] = mtspectrumc(tempR_', EEG_PARAMS.params);

figL = figure;
plot(fL, pL);
title(titleL);
xlabel('Frequency');ylabel('Power');

figR = figure;
plot(fR, pR);
title(titleR);
xlabel('Frequency');ylabel('Power');
