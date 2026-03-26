function realtimeEEGClassifier_CSV(csvFile, SVMModel, Fs, chSel, nFFT, step, hannWin, updateDisplay)
%% REAL-TIME SSVEP CLASSIFIER FROM CSV FILE (No LSL / No Python needed)
% csvFile       : path to a Unicorn Recorder CSV file (8 EEG channels)
% SVMModel      : trained SVM classifier
% Fs            : sampling rate (Hz)
% chSel         : selected channel indices (e.g. [6 7 8])
% nFFT          : FFT window length in samples
% step          : step size in samples
% hannWin       : Hann window vector (1 x nFFT)
% updateDisplay : function handle to update PTB display (BCI input)

disp('Starting SSVEP classification from CSV file...');

%% ---------------- LOAD CSV DATA ----------------
data = readmatrix(csvFile);
eeg = data(:,1:8)';             % 8 channels x samples
eeg = eeg(chSel, :);            % select channels
eeg = eeg - mean(eeg, 1);       % average rereference

nSamples = size(eeg, 2);
nSelChannels = length(chSel);

%% ---------------- BUFFERS ----------------
eegBuffer = zeros(nSelChannels, nFFT);
lastDecisions = [];
lastBCI = NaN;
currentIdx = 1;

%% ---------------- MAIN LOOP ----------------
disp('Running classification loop (CSV playback)...');
fprintf('Total samples: %d | Step: %d | Windows: ~%d\n', ...
    nSamples, step, floor((nSamples - nFFT) / step));

while currentIdx + nFFT - 1 <= nSamples

    % --- Grab a chunk of data (simulating real-time) ---
    chunkEnd = min(currentIdx + step - 1, nSamples);
    eegChunk = eeg(:, currentIdx:chunkEnd);
    nNew = size(eegChunk, 2);

    % --- Update rolling buffer ---
    if nNew >= nFFT
        eegBuffer = eegChunk(:, end-nFFT+1:end);
    else
        eegBuffer = [eegBuffer(:, nNew+1:end), eegChunk];
    end

    % --- Feature extraction ---
    seg = detrend(eegBuffer')';
    seg = seg .* hannWin;

    fftVals = abs(fft(seg, [], 2));
    fftVals = fftVals(:, 1:floor(nFFT/2));
    faxis = linspace(0, Fs/2, floor(nFFT/2));

    % Bands for SSVEP (15 Hz & 20 Hz + harmonics)
    bands = [13 17; 28 32; 18 22; 38 42];
    feat = [];
    for b = 1:size(bands,1)
        idxBand = faxis >= bands(b,1) & faxis <= bands(b,2);
        feat = [feat mean(fftVals(:, idxBand), 'all')];
    end

    % --- Classifier prediction ---
    pred = predict(SVMModel, feat);   % 1=15Hz, 2=20Hz
    windowOutput = pred - 1;          % 0=15Hz (rotate), 1=20Hz (select)

    % --- 3-window stability check ---
    lastDecisions = [lastDecisions windowOutput];
    if length(lastDecisions) >= 3
        recent = lastDecisions(end-2:end);
        if numel(unique(recent)) == 1
            bciInput = recent(end);
            if bciInput ~= lastBCI
                lastBCI = bciInput;
                if bciInput == 0
                    fprintf('  → ROTATE knob\n');
                else
                    fprintf('  → SELECT\n');
                end
                % --- Update display ---
                if ~isempty(updateDisplay)
                    updateDisplay(bciInput);
                end
            end
        end
    end

    % --- Advance ---
    currentIdx = currentIdx + step;

    % --- Pace playback to simulate real-time ---
    pause(step / Fs);
end

disp('CSV classification complete.');
end
