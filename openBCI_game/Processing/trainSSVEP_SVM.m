function SVMModel = trainSSVEP_SVM(file14, file18, Fs, chSel, freqs, harms, nFFT, step, hannWin)

    [X14] = extractFeaturesFromCSV(file14, Fs, chSel, freqs, harms, nFFT, step, hannWin);
    [X18] = extractFeaturesFromCSV(file18, Fs, chSel, freqs, harms, nFFT, step, hannWin);

    X = [X14; X18];
    y = [ones(size(X14,1),1); 2*ones(size(X18,1),1)];

    SVMModel = fitcsvm(X, y, 'KernelFunction','linear', 'Standardize',true);
end