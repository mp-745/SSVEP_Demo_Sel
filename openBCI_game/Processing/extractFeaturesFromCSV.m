function features = extractFeaturesFromCSV(filename, Fs, chSel, freqs, harms, nFFT, step, hannWin)

    data = readmatrix(filename);
    eeg = data(:,1:8)';
    eeg = eeg(chSel,:);
    eeg = eeg - mean(eeg,1);

    nSamples = size(eeg,2);
    idx = 1;
    features = [];

    while idx + nFFT - 1 <= nSamples
        seg = eeg(:, idx:idx+nFFT-1);
        seg = detrend(seg')';
        seg = seg .* hannWin;

        fftVals = abs(fft(seg, [], 2));
        fftVals = fftVals(:,1:floor(nFFT/2));
        faxis = linspace(0, Fs/2, floor(nFFT/2));

        feat = [];
        for f = freqs
            for h = harms
                band = f*h;
                idxBand = faxis >= band-0.5 & faxis <= band+0.5;
                feat = [feat mean(fftVals(:,idxBand),'all')];
            end
        end

        features = [features; feat];
        idx = idx + step;
    end
end