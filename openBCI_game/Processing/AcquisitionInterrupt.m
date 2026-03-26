KbEventFlush(0);
[keyIsDown, ~, keyCode, ~] = KbCheck(0);
if keyIsDown && any(find(keyCode) == 68)
   breakLoop = true;
end

%value_of_KB_char = KbName('<enter keyboard character here'>);