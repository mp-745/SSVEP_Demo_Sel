close all; clear; clc;

%% Setup Psychtoolbox screen
Screen('Preference', 'SkipSyncTests', 1); % Skip sync tests for testing
screenID = max(Screen('Screens'));
[win, winRect] = Screen('OpenWindow', screenID, [0 0 0]); % black background
Screen('TextSize', win, 40);
DrawFormattedText(win, 'Press S to start Game', 'center', 'center', [255 255 255]);
Screen('Flip', win);

%% Game logic variables
block_on = false;
trial_on = false;
tr = 1;

%% Setup figure for key press detection
currentKey = '';

%% Main loop
while true
    % Check for key press
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown
        key = KbName(find(keyCode));
        if iscell(key)
            key = key{1}; % in case multiple keys are pressed
        end
        currentKey = lower(key); % lowercase for consistency
        KbReleaseWait; % wait until key released
    end

    % ---------- BLOCK LOGIC via keyboard ----------
    switch currentKey
        case 's'   % Start game block
            if ~block_on
                block_on = true;
                block_type = 'Game';
                tr = 1;
                Screen('FillRect', win, [0 128 0]); % green screen = game started
                DrawFormattedText(win, 'Game Block Started!', 'center', 'center', [255 255 255]);
                Screen('Flip', win);
                disp('Game block started');
            end

        case 't'   % Start trial
            if block_on && ~trial_on
                trial_on = true;
                Screen('FillRect', win, [0 0 128]); % blue screen = trial
                DrawFormattedText(win, ['Trial ' num2str(tr) ' Started'], 'center', 'center', [255 255 255]);
                Screen('Flip', win);
                disp(['Trial ' num2str(tr) ' started']);
            end

        case 'p'   % Stop trial
            if trial_on
                trial_on = false;
                tr = tr + 1;
                Screen('FillRect', win, [128 128 128]); % grey screen = trial stopped
                DrawFormattedText(win, 'Trial Stopped', 'center', 'center', [255 255 255]);
                Screen('Flip', win);
                disp('Trial stopped');
            end

        case 'escape'   % Stop block
            if block_on
                block_on = false;
                trial_on = false;
                Screen('FillRect', win, [0 0 0]); % black screen
                DrawFormattedText(win, 'Game Block Stopped', 'center', 'center', [255 255 255]);
                Screen('Flip', win);
                disp('Game block stopped');
            end
    end

    currentKey = ''; % reset key
end

%% Close screen on exit (never reached in this infinite loop)
Screen('CloseAll');