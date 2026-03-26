clear all; clc;close all;

%% SSVEP Frequencies
SSVEP_Freq = [15 20];

%% Initialisation
monitor             = 0;
EEG_flag            = false;
openbci_flag        = true;
openbci_flag2       = false;
Background_color    = [0 0 0];
InitMain;
InitPresentationPaths;
StimuliInit;
Stimuli_grating;


ShipBiasL = 1;
ShipBiasR = 1;

%% Main
while true
    Stimuli_game;
    BlockType;
    if exit_flag
        break
    else
        GameMain;
    end
end

%% Exit
sca;