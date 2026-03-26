function realtimeEEGClassifier(SVMModel, Fs, chSel, nFFT, step, hannWin, updateDisplay)
%% REAL-TIME SSVEP CLASSIFIER USING LSL (Unicorn)
% SVMModel      : trained SVM classifier
% Fs            : sampling rate
% chSel         : selected channels
% nFFT          : FFT window length in samples
% step          : step size in samples
% hannWin       : Hann window for FFT
% updateDisplay : function handle to update PTB display (BCI input)

disp('Starting real-time SSVEP classification via LSL...');

%% ---------------- SETUP LSL ----------------
lib = lsl_loadlib();
result = {};
disp('Resolving Unicorn EEG stream...');
while isempty(result)
    result = lsl_resolve_byprop(lib, 'name', 'UnicornRecorderLSLStream');
    pause(0.1);
end
disp('Opening inlet...');
inlet = lsl_inlet(result{1}, 1.0);

nChannelsTotal = 8;
nSelChannels = length(chSel);

%% ---------------- BUFFERS ----------------
eegBuffer = zeros(nSelChannels, nFFT);  % rolling buffer for window
lastDecisions = [];
lastBCI = NaN;

%% ---------------- MAIN LOOP ----------------
disp('Running real-time loop...');
while true
    % Pull chunk from LSL
    [chunk, ~] = inlet.pull_chunk();
    if isempty(chunk)
        pause(0.001);
        continue;
    end

    % Select channels
    eegChunk = chunk(chSel, :);

    % Average rereference
    eegChunk = eegChunk - mean(eegChunk, 1);

    % Update rolling buffer
    nNew = size(eegChunk, 2);
    if nNew >= nFFT
        eegBuffer = eegChunk(:, end-nFFT+1:end);
    else
        eegBuffer = [eegBuffer(:, nNew+1:end), eegChunk];
    end

    % Only classify when enough samples
    if size(eegBuffer, 2) < nFFT
        continue;
    end

    % --- Feature extraction ---
    seg = detrend(eegBuffer')';        % linear detrend
    seg = seg .* hannWin;

    fftVals = abs(fft(seg, [], 2));
    fftVals = fftVals(:, 1:floor(nFFT/2));
    faxis = linspace(0, Fs/2, floor(nFFT/2));

    % Bands for SSVEP
    bands = [13 17; 28 32; 18 22; 38 42];  % 15Hz & 20Hz + harmonics
    feat = [];
    for b = 1:size(bands,1)
        idxBand = faxis >= bands(b,1) & faxis <= bands(b,2);
        feat = [feat mean(fftVals(:, idxBand), 'all')];
    end

    % --- Classifier prediction ---
    pred = predict(SVMModel, feat);   % 1=15Hz, 2=20Hz
    windowOutput = pred - 1;          % 0=15Hz, 1=20Hz

    % --- 3-window stability ---
    lastDecisions = [lastDecisions windowOutput];
    if length(lastDecisions) >= 3
        recent = lastDecisions(end-2:end);
        if numel(unique(recent)) == 1
            bciInput = recent(end);
            if bciInput ~= lastBCI
                lastBCI = bciInput;
                % --- update PTB display ---
                if ~isempty(updateDisplay)
                    updateDisplay(bciInput);
                end
            end
        end
    end

    % --- Step forward ---
    if nNew >= step
        eegBuffer = eegBuffer(:, step+1:end);
    end

    pause(step/Fs);  % simulate real-time pacing
end
end
