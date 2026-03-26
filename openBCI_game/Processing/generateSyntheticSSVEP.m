function generateSyntheticSSVEP(file15, file20, Fs, duration)
%% GENERATE SYNTHETIC SSVEP CSV FILES FOR DEMO/TESTING
% Creates two CSV files that mimic Unicorn Recorder output:
%   - file15: 8-channel EEG with a 15 Hz SSVEP signal on channels 6-8
%   - file20: 8-channel EEG with a 20 Hz SSVEP signal on channels 6-8
%
% Each file has 8 columns (EEG channels), 250 Hz sampling rate.
% Channels 6-8 (occipital) contain the SSVEP signal + noise.
% Channels 1-5 contain only noise.
%
% Inputs:
%   file15   : output path for the 15 Hz CSV
%   file20   : output path for the 20 Hz CSV
%   Fs       : sampling rate (default 250)
%   duration : seconds of data to generate (default 30)

if nargin < 3, Fs = 250; end
if nargin < 4, duration = 30; end

nSamples = Fs * duration;
t = (0:nSamples-1) / Fs;

% --- Generate 15 Hz file ---
data15 = generateSSVEPData(t, 15, Fs, nSamples);
ensureDir(file15);
writematrix(data15, file15);
fprintf('Generated 15 Hz synthetic data: %s (%d samples)\n', file15, nSamples);

% --- Generate 20 Hz file ---
data20 = generateSSVEPData(t, 20, Fs, nSamples);
ensureDir(file20);
writematrix(data20, file20);
fprintf('Generated 20 Hz synthetic data: %s (%d samples)\n', file20, nSamples);

end

function data = generateSSVEPData(t, targetFreq, Fs, nSamples)
    nChannels = 8;
    data = zeros(nSamples, nChannels);

    % Background noise on all channels (realistic EEG ~10-50 uV)
    noiseLevel = 15;  % uV
    for ch = 1:nChannels
        data(:, ch) = noiseLevel * randn(nSamples, 1);
    end

    % Add 1/f (pink noise) character to all channels
    for ch = 1:nChannels
        pinkNoise = cumsum(randn(nSamples, 1));
        pinkNoise = pinkNoise / std(pinkNoise) * 5;
        data(:, ch) = data(:, ch) + pinkNoise;
    end

    % Add alpha rhythm (~10 Hz) to occipital channels as background
    alphaAmp = 8;  % uV
    for ch = 6:8
        alphaPhase = 2*pi*rand();  % random phase per channel
        data(:, ch) = data(:, ch) + alphaAmp * sin(2*pi*10*t' + alphaPhase);
    end

    % Add SSVEP signal (fundamental + 2nd harmonic) to occipital channels 6-8
    ssvepAmp = 20;      % uV — fundamental
    harmonicAmp = 10;   % uV — 2nd harmonic
    for ch = 6:8
        phase1 = 2*pi*rand();
        phase2 = 2*pi*rand();
        data(:, ch) = data(:, ch) ...
            + ssvepAmp   * sin(2*pi*targetFreq*t'   + phase1) ...
            + harmonicAmp * sin(2*pi*2*targetFreq*t' + phase2);
    end
end

function ensureDir(filepath)
    [folder, ~, ~] = fileparts(filepath);
    if ~isfolder(folder)
        mkdir(folder);
    end
end
