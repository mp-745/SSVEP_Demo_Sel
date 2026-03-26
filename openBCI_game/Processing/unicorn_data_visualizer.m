%% Unicorn EEG Live Visualization (Time + FFT)
close all; clear; clc;

%% Parameters
Fs = 250;
bufferLength = 5;
updateInterval = 1.00; % 300ms

nSamplesBuffer = round(Fs * bufferLength);
nSamplesUpdate = round(Fs * updateInterval);

%% Electrode selection
selectedChannels = [6 7 8];   % 6-8 channels
nSelChannels = length(selectedChannels);
nChannels = 8;   % total Unicorn channels

%% LSL Setup
disp('Loading LSL library...');
lib = lsl_loadlib();

disp('Resolving Unicorn EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib, 'name', 'UnicornRecorderLSLStream');
end

disp('Opening inlet...');
inlet = lsl_inlet(result{1}, 1.0);

%% Buffers
eegBuffer = zeros(nSelChannels, nSamplesBuffer);
timeBuffer = linspace(-bufferLength, 0, nSamplesBuffer);

%% Figure
hFig = figure('Name','Unicorn EEG Live + FFT');

subplot(2,1,1);
hEEG = plot(timeBuffer, eegBuffer');
title('Live EEG (Selected Channels)');
xlabel('Time (s)'); ylabel('Amplitude (\muV)');
ylim([-50 50]); grid on;
legend(arrayfun(@(x) sprintf('Ch %d', x), ...
       selectedChannels, 'UniformOutput', false));

subplot(2,1,2);
freqs = linspace(0, Fs/2, floor(nSamplesUpdate/2));
hFFT = plot(freqs, zeros(size(freqs)));
title('FFT (Mean of Selected Channels)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
xlim([0 40]); ylim([0 250]); grid on;

lastUpdate = tic;

%% Main loop
while ishandle(hFig)

    [vec, ~] = inlet.pull_chunk();
    if isempty(vec)
        continue;
    end

    % Select electrodes
    eegChunk = vec(selectedChannels, :);

    % Average rereference
    eegChunk = eegChunk - mean(eegChunk, 1);

    % Update buffer
    nNew = size(eegChunk, 2);
    if nNew >= nSamplesBuffer
        eegBuffer = eegChunk(:, end-nSamplesBuffer+1:end);
    else
        eegBuffer = [eegBuffer(:, nNew+1:end), eegChunk];
    end

    % Update plots
    if toc(lastUpdate) >= updateInterval
        lastUpdate = tic;

        for ch = 1:nSelChannels
            set(hEEG(ch), 'YData', eegBuffer(ch,:));
        end

        recentData = eegBuffer(:, end-nSamplesUpdate+1:end);
        recentData = detrend(recentData')';

        fftVals = abs(fft(recentData, [], 2));
        fftVals = fftVals(:, 1:floor(nSamplesUpdate/2));
        meanFFT = mean(fftVals, 1);

        set(hFFT, 'XData', freqs, 'YData', meanFFT);
        drawnow;
    end
end

disp('Visualization stopped.');