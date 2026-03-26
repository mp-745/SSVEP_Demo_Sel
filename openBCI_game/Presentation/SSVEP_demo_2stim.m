clear; clc; close all;

%% ================= USER SETTINGS =================
EEG_flag = true;

nStimuli = input('Number of stimuli (1 or 2): ');          % 1 or 2
if nStimuli == 1
    singleStimSide = upper(input('Single stimulus side (L or R): ', 's'));

    while ~ismember(singleStimSide, {'L','R'})
        singleStimSide = upper(input('Invalid input. Enter L or R: ', 's'));
    end
else
    singleStimSide = '';  % not used
end

Background_color = [0 0 0];
r = 200;               % circle radius
offset = 800;          % distance from center (for 2-stim condition)

%% ================= INIT =================
InitMain;          % defines flicker_freq_L, flicker_freq_R, etc.
StimuliInit;       % opens PTB window and sets window, xc, yc, white, etc.

breakLoop = false;

%% ================= TIMING =================
ifi = Screen('GetFlipInterval', window);
refreshRate = 1 / ifi;

frames_L = round(refreshRate / flicker_freq_L);
frames_R = round(refreshRate / flicker_freq_R);

frameCount = 0;

%% ================= STIM POSITIONS =================
centerRect = [xc-r yc-r xc+r yc+r];
leftRect   = [xc-offset-r yc-r xc-offset+r yc+r];
rightRect  = [xc+offset-r yc-r xc+offset+r yc+r];

%% ================= STIMULUS LOOP =================
while true
    frameCount = frameCount + 1;

    Screen('FillRect', window, Background_color);

    if nStimuli == 1
        if strcmpi(singleStimSide, 'L')
            on = mod(frameCount, frames_L) < frames_L/2;
        else
            on = mod(frameCount, frames_R) < frames_R/2;
        end

        if on
            Screen('FillOval', window, white, centerRect);
        end
    else
        leftOn  = mod(frameCount, frames_L) < frames_L/2;
        rightOn = mod(frameCount, frames_R) < frames_R/2;

        if leftOn
            Screen('FillOval', window, white, leftRect);
        end
        if rightOn
            Screen('FillOval', window, white, rightRect);
        end
    end

    % ---- VBL synced flip ----
    if frameCount == 1
        vbl = Screen('Flip', window);
    else
        vbl = Screen('Flip', window, vbl + ifi);
    end

    TrialInterrupt;
    if breakLoop || exit_flag
        break;
    end
end

%% ================= CLEANUP =================
sca;
if exist('paraport','var')
    fclose(paraport);
end