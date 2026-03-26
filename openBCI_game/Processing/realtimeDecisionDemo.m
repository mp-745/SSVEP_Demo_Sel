function realtimeDecisionDemo(filename, model, Fs, chSel, freqs, harms, nFFT, step, hannWin, decisionCallback)
% %%% CHANGED: decisionCallback added

data = readmatrix(filename);
eeg = data(:,1:8)';             
eeg = eeg(chSel,:);             
eeg = eeg - mean(eeg,1);        

nSamples = size(eeg,2);
idx = 1;

lastDecisions = [];
lastTriggeredDecision = NaN;     % %%% ADDED: debounce lock

while idx + nFFT - 1 <= nSamples

    seg = eeg(:, idx:idx+nFFT-1);
    seg = detrend(seg')';        
    seg = seg .* hannWin;        

    fftVals = abs(fft(seg, [], 2));
    fftVals = fftVals(:,1:floor(nFFT/2));
    faxis = linspace(0, Fs/2, floor(nFFT/2));

    % -------- FEATURE EXTRACTION (MATCH VISUALIZATION) --------
    bands = [
        13 17;   % 15 Hz fundamental
        28 32;   % 15 Hz harmonic
        18 22;   % 20 Hz fundamental
        38 42    % 20 Hz harmonic
    ];

    feat = [];
    for b = 1:size(bands,1)
        idxBand = faxis >= bands(b,1) & faxis <= bands(b,2);
        feat = [feat mean(fftVals(:,idxBand),'all')];
    end

    pred = predict(model, feat);
    lastDecisions = [lastDecisions pred];

    % -------- STABLE DECISION CHECK --------
    if length(lastDecisions) >= 3
        recent = lastDecisions(end-2:end);

        if numel(unique(recent)) == 1
            stableDecision = recent(end);

            % %%% CHANGED: trigger only once per stable block
            if stableDecision ~= lastTriggeredDecision
                fprintf('STABLE OUTPUT → %d\n', stableDecision);

                if ~isempty(decisionCallback)
                    decisionCallback(stableDecision); % %%% ADDED
                end

                lastTriggeredDecision = stableDecision;
            end
        end
    end

    idx = idx + step;
    pause(step/Fs);   % simulate real-time
end
end
