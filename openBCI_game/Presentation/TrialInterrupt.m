[keyIsDown, ~, keyCode, ~] = KbCheck(0);
if keyIsDown && any(find(keyCode) == 27)
   breakLoop = true;
end