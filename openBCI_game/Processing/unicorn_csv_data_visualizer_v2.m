%% Unicorn EEG Visualization from CSV (Time + FFT)
close all; clear; clc;

%% Parameters
Fs = 250;
bufferLength = 5;            % seconds (visualization)

updateInterval = 0.25;       % seconds  
fftWindow = 2.0;             % seconds  

nSamplesBuffer = round(Fs * bufferLength);
nSamplesUpdate = round(Fs * updateInterval);
nFFT = round(Fs * fftWindow);   

%% Electrode selection
selectedChannels = [6 7 8]; % occipital electrodes selected
nSelChannels = length(selectedChannels);
nChannels = 8;

%% Load CSV
%filename = 'C:\Users\maxpo\OneDrive\Documents\gtec\Unicorn Suite\Hybrid Black\Unicorn Recorder\Sample data\14 Hz\UnicornRecorder_16_01_2026_16_24_340.csv';
%filename = 'C:\Users\maxpo\OneDrive\Documents\gtec\Unicorn Suite\Hybrid Black\Unicorn Recorder\Sample data\16 Hz\UnicornRecorder_16_01_2026_16_31_160.csv';
filename = 'C:\Users\maxpo\OneDrive\Documents\gtec\Unicorn Suite\Hybrid Black\Unicorn Recorder\Sample data\18 Hz\UnicornRecorder_16_01_2026_16_27_410.csv';
data = readmatrix(filename);

% Columns 1–8 = EEG, 9 = trigger
eegData = data(:,1:nChannels)';   % channels × samples
nSamplesTotal = size(eegData,2);

%% Buffers
eegBuffer = zeros(nSelChannels, nSamplesBuffer);
timeBuffer = linspace(-bufferLength, 0, nSamplesBuffer);

%% Figure
hFig = figure('Name','Unicorn EEG CSV Playback');

subplot(2,1,1);
hEEG = plot(timeBuffer, eegBuffer');
ylim([-50 50]); grid on;
xlabel('Time (s)'); ylabel('Amplitude (\muV)');
legend(arrayfun(@(x) sprintf('Ch %d',x),selectedChannels,'UniformOutput',false));

subplot(2,1,2);
freqs = linspace(0, Fs/2, floor(nFFT/2));   
hFFT = plot(freqs, zeros(size(freqs)));
xlim([0 40]); ylim([0 250]); grid on;
xlabel('Frequency (Hz)'); ylabel('Magnitude');

%% Playback loop
currentIdx = 1;

hannWin = hann(nFFT)';  

while ishandle(hFig) && currentIdx <= nSamplesTotal

    nChunk = min(nSamplesUpdate, nSamplesTotal - currentIdx + 1);
    eegChunk = eegData(selectedChannels, currentIdx:currentIdx+nChunk-1);

    % Average rereference
    eegChunk = eegChunk - mean(eegChunk,1);

    % Update rolling buffer
    eegBuffer = [eegBuffer(:,nChunk+1:end), eegChunk];

    % --- Update EEG plot ---
    for ch = 1:nSelChannels
        set(hEEG(ch),'YData',eegBuffer(ch,:));
    end

    % -------- FFT (SSVEP-correct) --------
    if size(eegBuffer,2) >= nFFT

        recentData = eegBuffer(:, end-nFFT+1:end);    % (CHANGED)
        recentData = detrend(recentData')';           % linear detrend

        recentData = recentData .* hannWin;           % (ADDED)

        fftVals = abs(fft(recentData, [], 2));
        fftVals = fftVals(:, 1:floor(nFFT/2));

        meanFFT = mean(fftVals, 1);

        set(hFFT, 'XData', freqs, 'YData', meanFFT);
    end

    drawnow;

    currentIdx = currentIdx + nChunk;

    % Simulate real-time
    pause(updateInterval);
end

disp('Visualization finished.');