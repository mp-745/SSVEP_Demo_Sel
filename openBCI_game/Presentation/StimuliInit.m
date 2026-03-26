monitor = max(Screen('Screens')); %
[window, windowRect] = Screen('OpenWindow',monitor,Background_color);
if exist('window', 'var')
    black = BlackIndex(window); white = WhiteIndex(window);gray = round(white/2); yellow = [1 1 0]*white;
else
    black = 0; white = 255;gray = white/2; yellow = [1 1 0]*white;
end
%     HideCursor(); %Hide Cursor
Screen('Flip', window);
MonitorFlipInterval = Screen('GetFlipInterval', window);
ScreenRefRate = round(1/MonitorFlipInterval);
topPriorityLevel = MaxPriority(window);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);
xc = xCenter; yc = yCenter;

