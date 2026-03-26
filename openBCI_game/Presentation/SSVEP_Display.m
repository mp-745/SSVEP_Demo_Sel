function SSVEP_Display()
%% PTB DISPLAY WITH BCI INTEGRATION
InitMain;
StimuliInit;

breakLoop = false;
stopFlag  = false;
knobIndex = 1;
numTicks  = 8;

% Store state in figure UserData
set(window,'UserData',struct('knobIndex',knobIndex,'numTicks',numTicks,'selectIndex',[]));

KbName('UnifyKeyNames');
escapeKey = KbName('ESCAPE');

while ~breakLoop && ~stopFlag
    % --- update knob state from UserData ---
    state = get(window,'UserData');
    if ~isempty(state.knobIndex)
        knobIndex = state.knobIndex;
    end
    selectIndex = [];
    if isfield(state,'selectIndex'), selectIndex = state.selectIndex; end
    
    % --- DRAW EVERYTHING ---
    Screen('FillRect', window, [0 0 0]);
    
    % Title
    Screen('TextSize', window, 150);
    titleBounds = Screen('TextBounds', window, 'DRUMS');
    Screen('DrawText', window, 'DRUMS', state.xc - titleBounds(3)/2, state.yc - 1200, state.white);
    
    % Knob circle
    Screen('FillOval', window, [120 120 120], state.knobRect);
    
    % Knob pointer
    anglePointer = -135 + (knobIndex-1)*(315/(numTicks-1));
    xEnd = state.xc + 120*cosd(anglePointer);
    yEnd = state.yc + 120*sind(anglePointer);
    Screen('DrawLine', window, state.white, state.xc, state.yc, xEnd, yEnd, 6);
    
    % Ticks and words
    for k = 1:numTicks
        angle = -135 + (k-1)*(315/(numTicks-1));
        % Tick
        x1 = state.xc + 135*cosd(angle); y1 = state.yc + 135*sind(angle);
        x2 = state.xc + 150*cosd(angle); y2 = state.yc + 150*sind(angle);
        Screen('DrawLine', window, state.white, x1,y1,x2,y2,4);
        % Word
        xWord = state.xc + 175*cosd(angle); yWord = state.yc + 175*sind(angle);
        wordStr = state.tickWords{k};
        if k == knobIndex || k == selectIndex
            fontSize = 36; % bold/large
        else
            fontSize = 28;
        end
        Screen('TextSize', window, fontSize);
        bounds = Screen('TextBounds', window, wordStr);
        Screen('DrawText', window, wordStr, xWord-bounds(3)/2, yWord-bounds(4)/2, state.white);
    end
    
    % Flickering SSVEP stimuli
    leftOn  = mod(state.frameCount,state.frames_L)<state.frames_L/2;
    rightOn = mod(state.frameCount,state.frames_R)<state.frames_R/2;
    if leftOn, Screen('FillOval', window, state.white, state.leftRect); end
    if rightOn, Screen('FillOval', window, state.white, state.rightRect); end
    
    % Flip
    if state.frameCount == 1
        vbl = Screen('Flip', window);
    else
        vbl = Screen('Flip', window, vbl + state.ifi);
    end
    
    % Esc key exit
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(escapeKey)
        stopFlag = true;
    end
    
    TrialInterrupt;
end

sca;
