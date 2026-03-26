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
triggers.block_stop = 253;

% Data
electrodes = EEG_PARAMS.electrodes;
ring_buffer_size = RT_PARAMS.ring_buffer_size;
ring_buffer = zeros(length(electrodes),ring_buffer_size);

% FB Files

feedback_file_name = '\\Biosemi-Win32\Users\Public\Documents\ft_shared.txt';

% Misc

trial_no = 0;

