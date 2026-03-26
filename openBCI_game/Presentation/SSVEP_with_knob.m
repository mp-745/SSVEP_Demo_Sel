clear; clc; close all;

%% ================= USER SETTINGS =================
EEG_flag = true;

Background_color = [0 0 0];
r = 200;               % circle radius
offset = 900;          % distance from center (for 2-stim condition)

tickWords = {'Beat 8','Beat 1','Beat 2','Beat 3','Beat 4','Beat 5','Beat 6','Beat 7'};

stimYOffset   = 400;    % pushes SSVEP stimuli downward
labelOffsetY  = 150;     % distance of label above stimulus
labelTextSize = 45;

%% ================= KNOB SETTINGS =================
knobRadius      = 120;
knobColor       = [120 120 120];   % grey
pointerLength   = 120;
pointerWidth    = 6;

numTicks        = 8;
tickLength      = 15;
tickWidth       = 4;
tickRadius      = knobRadius + 15;

labelExtraOffset = 25;   % additional spacing beyond ticks
TickLabelRadius = tickRadius + tickLength + labelExtraOffset;
textSize        = 28;

titleText      = 'DRUMS';
titleTextSize  = 150;   % large title
titleOffsetY   = 400;  % distance above knob center


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

% Center (unused for flicker now, but kept if needed)
centerRect = [xc-r yc-r xc+r yc+r];

% Move stimuli lower on screen
stimY = yc + stimYOffset;

% Near bottom corners
leftRect  = [xc-offset-r stimY-r xc-offset+r stimY+r];
rightRect = [xc+offset-r stimY-r xc+offset+r stimY+r];

% Knob stays centered
knobRect = [xc-knobRadius yc-knobRadius xc+knobRadius yc+knobRadius];

%% ================= STIMULUS LOOP =================
while true
    frameCount = frameCount + 1;

    Screen('FillRect', window, Background_color);

    %% ================= DRAW TITLE =================
    Screen('TextSize', window, titleTextSize);
    
    titleBounds = Screen('TextBounds', window, titleText);
    xTitle = xc - titleBounds(3)/2;
    yTitle = yc - knobRadius - titleOffsetY;
    
    Screen('DrawText', window, titleText, xTitle, yTitle, white);
    
    %% ================= DRAW KNOB =================
    
    % Set text size once per frame
    Screen('TextSize', window, textSize);
    
    % --- Draw grey knob ---
    Screen('FillOval', window, knobColor, knobRect);
    
    % --- Draw pointer (upwards) ---
    anglePointer = -90;  % degrees
    xEnd = xc + pointerLength * cosd(anglePointer);
    yEnd = yc + pointerLength * sind(anglePointer);
    
    Screen('DrawLine', window, white, xc, yc, xEnd, yEnd, pointerWidth);
    
    % --- Draw ticks and words ---
    for k = 1:numTicks
    
        % Spread over upper 315 degrees
        angle = -135 + (k-1) * (315/(numTicks-1));
    
        % Tick positions
        x1 = xc + tickRadius * cosd(angle);
        y1 = yc + tickRadius * sind(angle);
        x2 = xc + (tickRadius + tickLength) * cosd(angle);
        y2 = yc + (tickRadius + tickLength) * sind(angle);
    
        Screen('DrawLine', window, white, x1, y1, x2, y2, tickWidth);
    
        % Word positions
        xWord = xc + TickLabelRadius * cosd(angle);
        yWord = yc + TickLabelRadius * sind(angle);
    
        wordStr = tickWords{k};  % Get the word based on the current tick (1-8)
    
        % Center the word text
        bounds = Screen('TextBounds', window, wordStr);
        Screen('DrawText', window, wordStr, ...
            xWord - bounds(3)/2, ...
            yWord - bounds(4)/2, ...
            white);
    end

    %% ================= DRAW SSVEP LABELS =================
    Screen('TextSize', window, labelTextSize);
    
    % ---- Left label (15 Hz) ----
    leftLabel = 'ROTATE KNOB';
    boundsL = Screen('TextBounds', window, leftLabel);
    xLeftLabel = (leftRect(1) + leftRect(3))/2 - boundsL(3)/2;
    yLeftLabel = leftRect(2) - labelOffsetY;
    Screen('DrawText', window, leftLabel, xLeftLabel, yLeftLabel, white);
    
    % ---- Right label (20 Hz) ----
    rightLabel = 'SELECT';
    boundsR = Screen('TextBounds', window, rightLabel);
    xRightLabel = (rightRect(1) + rightRect(3))/2 - boundsR(3)/2;
    yRightLabel = rightRect(2) - labelOffsetY;
    Screen('DrawText', window, rightLabel, xRightLabel, yRightLabel, white);

    leftOn  = mod(frameCount, frames_L) < frames_L/2;
    rightOn = mod(frameCount, frames_R) < frames_R/2;

    if leftOn
        Screen('FillOval', window, white, leftRect);
    end
    if rightOn
        Screen('FillOval', window, white, rightRect);
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