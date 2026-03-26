%% BCI_main.m — SSVEP BCI: Training + Online Control
%
% This script can run in two modes:
%   MODE = 'csv'  → Uses a pre-recorded CSV file for classification (DEFAULT)
%                    No Python, no LSL, no headset needed.
%   MODE = 'lsl'  → Connects to a live Unicorn EEG stream via LSL
%                    Requires the Python LSL streamer (or Unicorn Recorder) running.
%
% Change the MODE variable below to switch.

close all; clear; clc;

%% ---------------- ADD PATHS ----------------
addpath(genpath(fullfile('..', 'Libraries')));
addpath(genpath(fullfile('..', 'Processing')));

%% ---------------- MODE SELECTION ----------------
MODE = 'csv';   % 'csv' = offline CSV playback (no Python needed)
                 % 'lsl' = live LSL stream (requires Python streamer or Unicorn Recorder)

%% ---------------- PARAMETERS ----------------
Fs = 250;
selectedChannels = [6 7 8];
SSVEP_freqs    = [15 20];      % target frequencies (Hz)
harmonics      = [1 2];        % harmonics to include

fftWindow      = 2.0;          % seconds
updateInterval = 0.25;         % seconds
nFFT           = round(Fs * fftWindow);
stepSamples    = round(Fs * updateInterval);
hannWin        = hann(nFFT)';

%% ---------------- TRAINING FILES ----------------
% Point these at real Unicorn Recorder CSVs if you have them.
% If the files don't exist, synthetic SSVEP data is auto-generated.
file15 = fullfile('..', 'Processing', 'SampleData', 'synthetic_15Hz.csv');
file20 = fullfile('..', 'Processing', 'SampleData', 'synthetic_20Hz.csv');

% --- Auto-generate synthetic data if files are missing ---
if ~isfile(file15) || ~isfile(file20)
    disp('Training CSV files not found. Generating synthetic SSVEP data...');
    generateSyntheticSSVEP(file15, file20, Fs, 30);  % 30 seconds of data
    disp('Synthetic data generated.');
end

%% ---------------- CSV TEST FILE (for 'csv' mode) ----------------
% This file is used as the "live" EEG source when MODE = 'csv'.
% Point it at any Unicorn CSV recording you want to play back.
csvTestFile = file15;   % default: replay the 15 Hz training file

%% ---------------- TRAIN SVM ----------------
disp('Training SSVEP SVM...');
SVMModel = trainSSVEP_SVM(file15, file20, Fs, selectedChannels, SSVEP_freqs, harmonics, nFFT, stepSamples, hannWin);
disp('Training complete.');

%% ---------------- START DISPLAY ----------------
disp('Launching knob display...');
updateKnob = SSVEP_Display_Fig();   % standard MATLAB figure (no Psychtoolbox needed)

%% ---------------- START CLASSIFIER ----------------
if strcmpi(MODE, 'csv')
    fprintf('\n=== CSV MODE: Playing back %s ===\n', csvTestFile);
    disp('No Python or LSL stream required.');
    realtimeEEGClassifier_CSV(csvTestFile, SVMModel, Fs, selectedChannels, ...
                              nFFT, stepSamples, hannWin, updateKnob);
elseif strcmpi(MODE, 'lsl')
    disp('=== LSL MODE: Connecting to live EEG stream ===');
    disp('Make sure the Python LSL streamer or Unicorn Recorder is running.');
    realtimeEEGClassifier(SVMModel, Fs, selectedChannels, ...
                          nFFT, stepSamples, hannWin, updateKnob);
else
    error('Unknown MODE "%s". Use ''csv'' or ''lsl''.', MODE);
end
