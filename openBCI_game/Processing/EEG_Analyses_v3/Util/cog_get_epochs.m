function [data_out,trials_info_out] = cog_get_epochs(data_in, triggers, type, varargin)

%%
% type = 1 - trial_start : trial_start + samples [3D Matrix - Ch x samples x Trials]
% type = 2 - trial_start : trial_stop [Cell array of 2D Matrices - Ch x samples(tr)]
% type = 3 - trial_start : trial_stop and each trial is divided into epochs (Len = samples and Step = step) ...
%     [3D Matrix - Ch x samples x Epochs]
% type = 4 - trial_start : trial_stop and each trial is divided into epochs (Len = samples and Step = step) ...
%     [Cell array of 3D Matrices - Ch x samples x Epochs]
% type = 5 - trial_start : trial_stop and each trial is divided into epochs and averaged per trial
%         (Len = samples and Step = step) [3D Matrix - Ch x samples x Trials]
%%

trig_start = [];
samples = [];
trig_stop = [];
step = [];
initial_cut = 0;
trials_info = [];
nan_epoch = false;
trials_info_out = {};

assignopts(who,varargin{:});

switch type
    case 1
        idx = find(triggers(:,1) == trig_start);
        for i=1:length(idx)
            data_out(:,:,i) = data_in(:,triggers(idx(i),2) + initial_cut : triggers(idx(i),2) + initial_cut + samples - 1);
        end
        if size(data_out,3) ~= length(trials_info)
            try
                trials_info_out = trials_info(1:size(data_out,3),:);
                warning('No of trials in EEG ~= behavior! Trying to truncate behavior data ...');
            catch
                error('Not Possible!');
            end
        else
            trials_info_out = trials_info;
        end
    case 2
        idx_start = find(triggers(:,1) == trig_start);
        idx_stop = find(triggers(:,1) == trig_stop);
        idx_start = idx_start(1:length(idx_stop));
        
        for i=1:length(idx_start)
            data_out{i} = data_in(:,triggers(idx_start(i),2) + initial_cut : triggers(idx_stop(i),2));
        end
        if length(data_out) ~= length(trials_info)
            try
                trials_info = trials_info(1:length(data_out),:);
                warning('No of trials in EEG ~= behavior! Trying to truncate behavior data ...');
            catch
                error('Not Possible!');
            end
        else
            trials_info_out = trials_info;
        end
    case {3,4,5}
        idx_start = find(triggers(:,1) == trig_start);
        idx_stop = find(triggers(:,1) == trig_stop);
        idx_start = idx_start(1:length(idx_stop));
        
        for i=1:length(idx_start)
            temp{i} = data_in(:,triggers(idx_start(i),2):triggers(idx_stop(i),2));
        end
        
        if length(temp) ~= length(trials_info)
            try
                trials_info = trials_info(1:length(temp),:);
                warning('No of trials in EEG ~= behavior! Trying to truncate behavior data ...');
            catch
                error('Not Possible!');
            end
        end
        
        for i=1:length(temp)
            data = temp{i}(:,initial_cut+1:end);
            no = floor((size(data,2)-samples)/step)+1;
            remdr = rem((size(data,2)-samples),step);
            if remdr<0
                error('Something Wrong!');
            end
            for j=1:no
                data_out{i}(:,:,j) = data(:,(j-1)*step+1:(j-1)*step + samples);
            end
            if remdr~=0 && nan_epoch
                data_out{i}(:,:,j+1) = [data(:,j*step+1:end) nan(size(data,1),step-remdr)];
            end
            if ~isempty(trials_info) && type == 3
                trials_info_out{i} = repmat(trials_info(i,:),[size(data_out{i},3),1]);
            else
                trials_info_out{i} = trials_info(i,:);
            end
        end
        
        if type == 3
            clear temp;
            temp = cat(3,data_out{:}); data_out = temp;
        end
        clear temp;
        temp = cat(1,trials_info_out{:}); trials_info_out = temp;
        
        if type == 5
            temp = [];
            trials_info_out = trials_info;
            for tr = 1:length(data_out)
               temp(:,:,tr) = nanmean(data_out{tr},3);
            end
            data_out = temp;
        end
        
end


end