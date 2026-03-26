breakLoop = false;
temp = NaN(1,32);
switch blocktype
    case 'Calibrate'
        %cog_send_triggers(paraport,100,EEG_flag);
        openbci_send_triggers(100, openbci_flag);
        for tr = 1:Trials
            tic;
            Screen('Flip',window);
            pause(1);
            %cog_send_triggers(paraport,20,EEG_flag)
            openbci_send_triggers(20, openbci_flag);
            while toc < TimeTrial
                TrialMain;
                TrialInterrupt;
                if breakLoop
                    break
                end
            end
            
            %cog_send_triggers(paraport,30,EEG_flag)
            openbci_send_triggers(30, openbci_flag);
            Screen('Flip',window);
            pause(1);
        end
        
        %cog_send_triggers(paraport,253,EEG_flag);
        openbci_send_triggers(253, openbci_flag);
        Wait_flag = true;
        pause(4.5);
        while Wait_flag
            f = fopen(acc_file_path,'r');
            Acc = fread(f,'double');
            if Acc ~= 0 %~isnan(Acc)
                DrawFormattedText(window, sprintf('Calibration Accuracy = %.2f \\n Press any key to continue',Acc*100),'center', 'center', yellow,[],[],[],2);
                Screen('Flip',window);
                KbWait(0);
                Wait_flag = false;
                fwrite(f,0,'double');
            else
                DrawFormattedText(window, 'Calibrating....' ,'center', 'center', yellow,[],[],[],2);
                Screen('Flip',window);
            end
            fclose(f);
        end
    case {'Practice','Game'}
        %cog_send_triggers(paraport,200,EEG_flag);
        if ~openbci_flag2
            openbci_send_triggers(200, openbci_flag); 
        end
        if openbci_flag
            openbci_flag2 = true;
        end
        Screen('Flip',window);
        pause(1);
        %cog_send_triggers(paraport,20,EEG_flag);
        openbci_send_triggers(20, openbci_flag);
        tic;
        temp = NaN(1,32);
        fid = fopen(FB_filepath,'r');
        while true
            TrialMain;
            TrialInterrupt;
            if breakLoop
                %cog_send_triggers(paraport,30,EEG_flag);
                openbci_send_triggers(30, openbci_flag);
                Screen('Flip',window);
                pause(1);
                fclose(fid);
                %cog_send_triggers(paraport,253,EEG_flag);
                break;
            end
        end
end