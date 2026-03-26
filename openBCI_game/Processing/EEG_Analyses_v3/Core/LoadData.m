function DATA_OUT = LoadData(SUBJECT_NO,RUN_NO,EEG_PARAMS)

filename = sprintf('raw_data\\RT_basic_S%d_run%d.gdf',SUBJECT_NO,RUN_NO);
data = ft_read_data(filename);
data = downsample(data',EEG_PARAMS.downsample_factor)'; 


Presentation_file = dir(sprintf('Presentation\\Run%d\\block*',RUN_NO));
load(sprintf('Presentation\\Run%d\\%s',RUN_NO,Presentation_file(1).name),'trials_info','flicker_freq_ON','flicker_freq_OFF','behaviour');
SSVEP_freq_pres = flicker_freq_ON;

event_line = data(1,:);
data = data(2:end,:);
data = data(EEG_PARAMS.electrodes,:);

DATA_OUT.data = data;
DATA_OUT.event_line = event_line;
DATA_OUT.SSVEP_freq = SSVEP_freq_pres;
DATA_OUT.trials_info = trials_info;
DATA_OUT.behavior = behaviour;
DATA_OUT.electrodes = EEG_PARAMS.electrodes;

end