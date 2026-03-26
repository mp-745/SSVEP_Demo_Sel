rGrating = 100; framePix = 25; totalPix = rGrating+framePix;
xPos = [totalPix screenXpixels - totalPix];
yPos = [screenYpixels - totalPix screenYpixels - totalPix];

location_L = [xPos(1) - rGrating, yPos(1) - rGrating, xPos(1) + rGrating, yPos(1) + rGrating];
location_R = [xPos(2) - rGrating, yPos(2) - rGrating, xPos(2) + rGrating, yPos(2) + rGrating];

rGrating = totalPix*sqrt(2);
xPos = [totalPix screenXpixels - totalPix];
yPos = [screenYpixels - totalPix screenYpixels - totalPix];

location_L_frame = [xPos(1) - rGrating, yPos(1) - rGrating, xPos(1) + rGrating, yPos(1) + rGrating];
location_R_frame = [xPos(2) - rGrating, yPos(2) - rGrating, xPos(2) + rGrating, yPos(2) + rGrating];

ScoreWindowPix = [150,170,50];
ScoreWindowLoc = [xc - ScoreWindowPix(2) screenYpixels; xc - ScoreWindowPix(1) screenYpixels - ScoreWindowPix(3) ;...
    xc + ScoreWindowPix(1) screenYpixels - ScoreWindowPix(3); xc + ScoreWindowPix(2) screenYpixels];

LR = {'Right >>>','<<< Left'};