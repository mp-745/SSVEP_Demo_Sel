function cog_send_triggers(paraport,name_of_trigger,flag)

switch name_of_trigger
    case 'pause_off'
        pval=254;
    case 'pause_on'
        pval=253;
    case 'fixation_leftCue'
        pval=11;
    case 'fixation_rightCue'
        pval=12;
    case 'trialstart'
        pval=20;
    case 'Cue'
        pval=25;
    case 'change_start'
        pval=28;
    case 'change_stop'
        pval=21;
    case 'trial_cutoffset'
        pval= 5;
    case 'trialstop'
        pval=30;
    case 'response'
        pval=40;
    case 'reset'
        pval=0;
    otherwise
        if isnumeric(name_of_trigger)
            pval = name_of_trigger;
        else
        error('ERROR: The name of the trigger mentioned is incorrect')
        end
end
if flag
    fwrite(paraport,pval);
else
    
end

end
