function offlineTestCSV(filename, model, Fs, chSel, freqs, harms, nFFT, step, hannWin)

    X = extractFeaturesFromCSV(filename, Fs, chSel, freqs, harms, nFFT, step, hannWin);
    preds = predict(model, X);

    fprintf('Window predictions:\n');
    disp(preds');

    finalDecision = mode(preds);

    if finalDecision == 1
        disp('Final decision: 15 Hz');
    else
        disp('Final decision: 20 Hz');
    end
end