date_str = datestr(now,'yyyy_mm_dd_hh_MM_ss');
filepath = [pwd '\' sprintf('RT_Data\\run%d_pilot_%s\\',RUN_NO,date_str)];
savepath = filepath;
mkdir(filepath);
fname =  sprintf('RT_S%d_run%d',SUBJECT_NO,RUN_NO);
SAVE_PARAMS.savepath = savepath;
SAVE_PARAMS.fname = fname;
SAVE_PARAMS.date_str = date_str;

% Misc params
Dist_type = {'normal','rician','exponential','beta','kernel'};
timesave = [];
