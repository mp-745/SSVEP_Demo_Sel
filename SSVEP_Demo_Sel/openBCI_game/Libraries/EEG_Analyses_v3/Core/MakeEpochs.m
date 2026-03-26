function DATA_OUT = MakeEpochs(DATA_IN,EEG_PARAMS,varargin)

Fs = EEG_PARAMS.Fs;
trig = EEG_PARAMS.trig;

epoch_length = 2*Fs;
step = epoch_length;
initial_cut = 1*Fs;
type = 1;
trials_info = DATA_IN.trials_info;
nan_epoch = false;

assignopts(who,varargin{:});

triggers_val = cog_get_triggers(DATA_IN.event_line);
opts = {'trig_start',trig.start,'trig_stop',trig.stop,'samples',epoch_length,...
    'step',step,'trials_info',trials_info,'initial_cut',initial_cut,'nan_epoch',nan_epoch};
[trialsFilt,trials_info] = cog_get_epochs(DATA_IN.data,triggers_val,type,opts);

LeftFlick_T_idx = find(trials_info(:,2)==0 & trials_info(:,6)==0);
RightFlick_T_idx = find(trials_info(:,2)==1 & trials_info(:,6)==1);

LeftFlick_D_idx = find(trials_info(:,2)==1 & trials_info(:,6)==0);
RightFlick_D_idx = find(trials_info(:,2)==0 & trials_info(:,6)==1);

Left_idx = find(trials_info(:,6)==0);
Right_idx = find(trials_info(:,6)==1);

DATA_OUT.epochs = trialsFilt;
DATA_OUT.Fs = Fs;
DATA_OUT.epoch_opts = [{type} opts];
DATA_OUT.trials_info = trials_info;
DATA_OUT.LeftFlick_T_idx = LeftFlick_T_idx;
DATA_OUT.RightFlick_T_idx = RightFlick_T_idx;
DATA_OUT.LeftFlick_D_idx = LeftFlick_D_idx;
DATA_OUT.RightFlick_D_idx = RightFlick_D_idx;
% DATA_OUT.Noise_idx = Noise_idx;
DATA_OUT.Left_idx = Left_idx;
DATA_OUT.Right_idx = Right_idx;

end