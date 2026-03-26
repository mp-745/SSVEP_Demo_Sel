function openbci_send_triggers(val, flag)
if flag
    fileID = fopen('C:\Users\maxpo\OneDrive\Documents\SSVEP_Demo_Sel\SSVEP_Demo_Sel\openBCI_game\SharedFiles\openbci_trig_values.txt','w');
    fwrite(fileID, val);
    fclose(fileID);
end