%% SSVEP Training + Testing Pipeline (15 Hz vs 20 Hz)
close all; clear; clc;

disp('SSVEP 15 Hz vs 20 Hz classification');

%% ---------------- Parameters ----------------
Fs              = 250;
selectedChannels = [6 7 8];
nChannels       = 8;

SSVEP_freqs     = [15 20];
harmonics       = [1 2];     % unused with the new band frequency selection 

fftWindow       = 2.0;       % seconds
updateInterval  = 0.25;      % seconds
nFFT            = round(Fs * fftWindow);
stepSamples     = round(Fs * updateInterval);

hannWin         = hann(nFFT)';

%% ---------------- Training files ----------------
file15 = 'C:\Users\maxpo\OneDrive\Documents\gtec\Unicorn Suite\Hybrid Black\Unicorn Recorder\Sample data\15 Hz\UnicornRecorder_16_01_2026_16_24_340.csv';   % 15 Hz data
file20 = 'C:\Users\maxpo\OneDrive\Documents\gtec\Unicorn Suite\Hybrid Black\Unicorn Recorder\Sample data\20 Hz\UnicornRecorder_16_01_2026_16_27_410.csv';   % 20 Hz data

%% ---------------- Train classifier ----------------
disp('Training classifier...');
[SVMModel] = trainSSVEP_SVM(file15, file20, Fs, selectedChannels, ...
                            SSVEP_freqs, harmonics, nFFT, stepSamples, hannWin);

save('SSVEP_SVM_Model.mat','SVMModel');
disp('Training complete.');

%% ---------------- TEST PHASE 1: Offline CSV ----------------
% testFile = 'C:\Users\maxpo\OneDrive\Documents\gtec\Unicorn Suite\Hybrid Black\Unicorn Recorder\Sample data\14 Hz\UnicornRecorder_16_01_2026_16_24_340.csv';   % unknown stimulus
% disp('Offline CSV testing...');
% offlineTestCSV(testFile, SVMModel, Fs, selectedChannels, ...
%                SSVEP_freqs, harmonics, nFFT, stepSamples, hannWin);

%% ---------------- TEST PHASE 2: Real-time ----------------
disp('Real-time testing (window-based)...');
realtimeDecisionDemo(testFile, SVMModel, Fs, selectedChannels, ...
                     SSVEP_freqs, harmonics, nFFT, stepSamples, hannWin);

disp('Done.');
