clear; clc;close all;

EEG_flag = true;
InitMain; 
Background_color = [0 0 0];
StimuliInit;
Stimuli_grating;
breakLoop = false;
tic; r = 200;
%%
while true
    
    Screen('FillOval', window, [(sin(pi*5*toc)).^2 0 0]*white, [xc-r yc-r xc+r yc+r]);
    Screen('Flip',window);
    TrialInterrupt;
    if breakLoop
        break;
    end
end
fclose(paraport);
sca;