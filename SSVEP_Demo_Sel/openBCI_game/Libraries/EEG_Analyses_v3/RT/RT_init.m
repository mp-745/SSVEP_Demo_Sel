% Feedback 

cut_off = 0.5;
delta = 0.02;

% Flags

trial_on = false;
FB_on = false;

% Triggers

triggers.trial_type = 11:18;
triggers.trial_start=20;
triggers.trial_cue=25;
triggers.trial_init_time=28;
triggers.trial_stop=30;
triggers.block_stop =253;

% Data
electrodes = EEG_PARAMS.electrodes;
ring_buffer_size = RT_PARAMS.ring_buffer_size;
ring_buffer = zeros(length(electrodes),ring_buffer_size);


% FB Files

% feedback_file_name = '\\10.0.0.2\Users\Public\ft_shared.txt';
% acc_file_name = '\\10.0.0.2\Users\Public\acc_shared.txt';
%%'C:\Users\Biosemi-Lab\Desktop\Hardware_Demo\IISc_open_day\Acquisition\acc_shared.txt';

feedback_file_name = 'C:\Users\Biosemi-Lab\Desktop\Hardware_Demo\IISc_open_day\Acquisition\ft_shared.txt';
acc_file_name = 'C:\Users\Biosemi-Lab\Desktop\Hardware_Demo\IISc_open_day\Acquisition\acc_shared.txt';

% Misc

trial_no = 0;
block_on = false;

