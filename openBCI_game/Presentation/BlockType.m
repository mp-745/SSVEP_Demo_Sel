Screen('TextSize', window, 30);
DrawFormattedText(window, 'Please choose an option: \n 1 - Calibrate \n 2 - Practice \n 3 - Game \n 4 - Exit', ...
    'center', 'center', yellow,[],[],[],2);
Screen('Flip',window);

while true
    [~, keyCode, ~] = KbWait(0);
    if any(find(keyCode) == 49) % Calibrate
        Trials = 10; TimeTrial = 6;
        Neurofeedback_flag = false;
        Object_flag = false;
        Obstacle_flag = false;
        blocktype = 'Calibrate';
    elseif any(find(keyCode) == 50) % Practice
        Neurofeedback_flag = true;
        Object_flag = true;
        Obstacle_flag = false;
        blocktype = 'Practice';
    elseif any(find(keyCode) == 51) % Game
        Neurofeedback_flag = true;
        Object_flag = true;
        Obstacle_flag = true;
        blocktype = 'Game';
    elseif any(find(keyCode) == 52) % Exit
        exit_flag = true;
        openbci_send_triggers(-1, openbci_flag);
    else
        continue;
    end
    break;
end
