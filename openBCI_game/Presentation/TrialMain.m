if Object_flag
    for i = 1:nObjects
        ObjectPos(:,2) = mod(ObjectPos(:,2)+speed,nYScreens_objects*screenYpixels);
        Screen('FillOval', window, ObjectColor, [ObjectPos(i,:) ObjectPos(i,:)+ObjectSize]);
    end
end

%%

if Obstacle_flag
    for i = 1:nObstacles
        ObstaclePos(:,2) = mod(ObstaclePos(:,2)+ObstacleSpeed, nYScreens*screenYpixels);
        Screen('FillOval', window, ObstacleColor, [ObstaclePos(i,:) ObstaclePos(i,:)+ObstacleSize]);
    end
    for i = 1:nEnemyShips
        EnemyShipPos(:,2) = mod(EnemyShipPos(:,2)+EnemyShipSpeed, nYScreens*screenYpixels);
        Screen('FillOval', window, EnemyShipColor, [EnemyShipPos(i,:) EnemyShipPos(i,:)+EnemyShipSize]);
    end
    
    ObstacleX = [ObstaclePos(:,1),ObstaclePos(:,1)+ObstacleSize/2,ObstaclePos(:,1)+ObstacleSize];
    ObstacleX = ObstacleX(:,[1,2,3,1,2,3]); ObstacleX = ObstacleX(:);
    ObstacleY = [ObstaclePos(:,2),ObstaclePos(:,2)+ObstacleSize/2,ObstaclePos(:,2)+ObstacleSize];
    ObstacleY = ObstacleY(:,[1,1,2,2,3,3]); ObstacleY = ObstacleY(:);
    
    EnimyShipX = [EnemyShipPos(:,1),EnemyShipPos(:,1)+EnemyShipSize/2,EnemyShipPos(:,1)+EnemyShipSize];
    EnimyShipX = EnimyShipX(:,[1,2,3,1,2,3]); EnimyShipX = EnimyShipX(:);
    EnimyShipY = [EnemyShipPos(:,2),EnemyShipPos(:,2)+EnemyShipSize/2,EnemyShipPos(:,2)+EnemyShipSize];
    EnimyShipY = EnimyShipY(:,[1,1,2,2,3,3]); EnimyShipY = EnimyShipY(:);
end

%%

if ~strcmp(blocktype, 'Calibrate') && openbci_flag2 
    fb_in_1 = fread(fid,'double');
    fseek(fid, 0, 'bof');
    if ismember(fb_in_1,[1 2])
        ShipDir = fb_in_1;
    end
%     if ismember(fb_in_1,[1,2])
%         temp = [temp(2:end) fb_in_1];
%     end
%     mode_temp = mode(temp);
%     if ismember(mode_temp,[1,2]) && sum(temp == mode_temp)>30
%         ShipDir = mode_temp;
%     end
else
    [keyIsDown, ~, keyCode, ~] = KbCheck(0);
    if keyIsDown && any(find(keyCode) == 37)
        ShipDir = 1;
    elseif keyIsDown && any(find(keyCode) == 39)
        ShipDir = 2;
    end
end

if ShipDir == 1 && ShipLoc(1) > ShipXlim(1)
    ShipLoc([1,3]) = ShipLoc([1,3])+(-1)*ShipSpeed*ShipBiasL;
elseif ShipDir == 2 && ShipLoc(3) < ShipXlim(2)
    ShipLoc([1,3]) = ShipLoc([1,3])+(+1)*ShipSpeed*ShipBiasR;
end

Screen('FillOval', window, [1 1 1]*white, ShipLoc);

%%

Screen('FillOval', window, [0 0 0], location_L_frame);
Screen('FillOval', window, [0 0 0], location_R_frame);
Screen('FrameOval', window, gray, location_L_frame, 5,5);
Screen('FrameOval', window, gray, location_R_frame, 5,5);

Screen('FillOval', window, [(sin(pi*flicker_freq_L*toc)).^2 0 0]*white, location_L);
Screen('FillOval', window, [0 (sin(pi*flicker_freq_R*toc)).^2 0]*white, location_R );

Screen('FrameOval', window, white, location_L, 2,2);
Screen('FrameOval', window, white , location_R, 2,2);

Screen('FillPoly', window, black, ScoreWindowLoc);
Screen('FramePoly', window, gray, ScoreWindowLoc,5);

Screen('TextSize', window, 30);

switch blocktype
    case 'Calibrate'
        DrawFormattedText(window, LR{mod(tr,2)+1},'center', screenYpixels - 12, yellow,[],[],[],2);
    case 'Practice'
        DrawFormattedText(window, 'Practice','center', screenYpixels - 12, yellow,[],[],[],2);
    case 'Game'
        DrawFormattedText(window, sprintf('SCORE = %.0f',2*toc+CollectedScore),'center', screenYpixels - 12, yellow,[],[],[],2);
end
%%

if Object_flag
    Collected_Objects = ObjectPos(:,1) > ShipLoc(1) & ObjectPos(:,1) < ShipLoc(3) ...
            & ObjectPos(:,2) > ShipLoc(2) & ObjectPos(:,2) < ShipLoc(4);
    if any(Collected_Objects)
        ObjectPos(find(Collected_Objects), 2) = screenYpixels;
        CollectedScore = CollectedScore + 5*length(find(Collected_Objects));
    end
end
%%

if Obstacle_flag
    if any(ObstacleX > ShipLoc(1) & ObstacleX < ShipLoc(3)  ...
            & ObstacleY > ShipLoc(2) & ObstacleY <  ShipLoc(4)) ||   ...
            any(EnimyShipX > ShipLoc(1) & EnimyShipX < ShipLoc(3)  ...
            & EnimyShipY > ShipLoc(2) & EnimyShipY <  ShipLoc(4))
        Screen('TextSize', window, 40);
        Screen('DrawText', window, 'GAME OVER!' ,xCenter - 150, yCenter - 50, yellow);
        Screen('Flip',window);
        pause(2);
        breakLoop = true;
%     elseif any(ObjectPos(:,1) > ShipLoc(1) & ObjectPos(:,1) < ShipLoc(3) ...
%             & ObjectPos(:,2) > ShipLoc(2) & ObjectPos(:,2) < ShipLoc(4))
%         disp('alriiiight!');
%         Screen('Flip',window);
    else
        Screen('Flip',window);
    end
else
    Screen('Flip',window);
end

%%

speed = speed + 0.0002*speed;
ObstacleSpeed = ObstacleSpeed + 0.0002*ObstacleSpeed;
ShipSpeed = ShipSpeed + 0.0002*ShipSpeed;
EnemyShipSpeed = EnemyShipSpeed + 0.0002*EnemyShipSpeed;
KbEventFlush(0);