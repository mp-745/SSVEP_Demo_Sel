%% Path Initialisation

%directory_path = 'C:\Users\Biosemi-Lab\Desktop\Prajwal\openBCI_game';
directory_path = 'C:\SSVEP_Demo_Sel\openBCI_game';

addpath(genpath(strcat(directory_path, '\Libraries\EEG_Analyses_v3')));
addpath(genpath(strcat(directory_path, '\Libraries\liblsl-Matlab')));

trig_file_path      = strcat(directory_path,'\SharedFiles\openbci_trig_values.txt');
acc_file_name       = strcat(directory_path,'\SharedFiles\acc_shared.txt');
feedback_file_name  = strcat(directory_path,'\SharedFiles\ft_shared.txt');
