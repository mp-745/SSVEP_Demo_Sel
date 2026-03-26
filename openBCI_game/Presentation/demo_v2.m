clear; clc;close all;

EEG_flag = false;
InitMain;
Background_color = [0 0 50];
StimuliInit;

ShipBiasL = 1;
ShipBiasR = 1;

%%
while true
    Stimuli_grating;
    Stimuli_game;
    BlockType;
    if exit_flag
        break
    else
        GameMain;
    end
end
fclose(paraport);
sca;