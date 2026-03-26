close all; clear all; clc;
disp('two stim classification');

%% Set SSVEP Frequencies & Subject Name
SSVEP_freq = [15 20];
Subject = 'OpenDay2023';

%% Add paths
InitPath;

%% Stream flags & parameters
eeg_flag            = true;
buffer_size         = 250;
Fs                  = 250;
maxBufferTime       = 1.0;
iter_count          = 1;
first_iter_flag     = true;
block_on            = false;
trial_on            = false;
num_DSS_comps       = 5;
breakLoop           = false;
save_flag           = 1;
final_vec_all       = [];
trig_fileID         = fopen(trig_file_path, 'r');
fid2                = fopen(feedback_file_name,'w');

load('PARAMS.mat','EEG_PARAMS','RT_PARAMS','METHOD_PARAMS');
EEG_PARAMS.SSVEP_freq = SSVEP_freq;

%%%% >>> UNICORN CHANGE <<< %%%%
EEG_PARAMS.channels   = 8;          % Unicorn has 8 EEG channels
EEG_PARAMS.electrodes = [6 7 8];    % Occipital electrodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init_params;
RT_reset;
InitSave;

%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

%% resolve a stream
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    %%%% >>> UNICORN CHANGE <<< %%%%
    % result = lsl_resolve_byprop(lib, 'name', 'UnicornRecorderRawDataLSLStream');

    result = lsl_resolve_byprop(lib, 'name', 'UnicornRecorderLSLStream');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1}, maxBufferTime);

%% Receive data
disp('Now receiving data...');
inlet.pull_chunk();

u = udpport("datagram","IPV4","LocalPort",1000);

while true

    % get data from the inlet
    [vec,ts] = inlet.pull_chunk();
    
    % Testing if receiving the data
    if ~isempty(vec)
        disp(['Received samples: ', num2str(size(vec,2))]);
        disp(vec(1:4,1:min(5,end)));   % print first 4 channels, first 5 samples
    end

    % adding rereferencing
    eeg_chunk = vec(1:EEG_PARAMS.channels,:);      % EEG only
    eeg_chunk = eeg_chunk - mean(eeg_chunk, 1);    % average rereferencing 
    
    if size(vec, 2) == 0
        continue;
    end

    % rolling buffer
    final_vec = [final_vec(:,size(vec,2)+1:end) ...
                 vec(1:EEG_PARAMS.channels,:)];

    % % Read triggers %% For openBCI
    % trig_value = fread(trig_fileID);
    % fseek(trig_fileID, 0, 'bof');
    % if isempty(trig_value)
    %     trig_value = 0;
    % end

    if u.NumDatagramsAvailable > 0
        data = read(u, u.NumDatagramsAvailable, "uint8");
        trig_value = double(data(end));   % last byte = trigger value
    else
        trig_value = 0;
    end

    % append raw data + trigger
    final_vec_all = [final_vec_all ...
        [vec(1:EEG_PARAMS.channels,:); ...
         ones([1, size(vec,2)])*trig_value]];

    % ---------- BLOCK LOGIC ----------

    % Calibration Block
    if trig_value == triggers.calib_block && ~block_on
        block_on = true;
        RT_reset;
        block_type = 'calibrate';
        tr = 1;
        EEG_Data = {};
    end

    % Game Block
    if trig_value == triggers.game_block && ~block_on
        block_on = true;
        block_type = 'Game';
        tr = 1;
        load('PARAMS.mat','EEG_PARAMS','RT_PARAMS','METHOD_PARAMS');
    end

    % Trial Start
    if trig_value == triggers.start_trial && first_iter_flag && block_on
        trial_on = true;
        first_iter_flag = false;
        RT_reset;
        EEG_Data{tr} = [];
    end

    % Trial Stop
    if trig_value == triggers.stop_trial && ~first_iter_flag && block_on
        trial_on = false;
        first_iter_flag = true;
        if strcmp(block_type, 'calibrate')
            EEG_Data{tr} = EEG_Data{tr}(:,Fs+1:4*Fs);
        end
        tr = tr + 1;
    end

    % Block Stop
    if trig_value == triggers.stop_block && block_on
        block_on = false;
        if strcmp(block_type, 'calibrate')

            % ---- calibration processing (UNCHANGED) ----
            Data{1} = cat(3,EEG_Data{1:2:length(EEG_Data)});
            sz = size(Data{1});
            Data{1} = reshape(Data{1},sz(1),EEG_PARAMS.Fs,[]);
            RT_Data{1} = reshape(Data{1},sz(1),RT_PARAMS.ring_buffer_size,[]);

            Data{2} = cat(3,EEG_Data{2:2:length(EEG_Data)});
            sz = size(Data{2});
            Data{2} = reshape(Data{2},sz(1),EEG_PARAMS.Fs,[]);
            RT_Data{2} = reshape(Data{2},sz(1),RT_PARAMS.ring_buffer_size,[]);

            for lr = 1:2
                for trial_no = 1:size(RT_Data{lr},3)
                    SSVEP_power_C((lr-1)*size(RT_Data{1},3)+trial_no,:) = ...
                        RT_SSVEP_noDSS(RT_Data{lr}(:,:,trial_no),EEG_PARAMS,METHOD_PARAMS);
                    labels((lr-1)*size(RT_Data{1},3)+trial_no,1) = lr;
                end
            end

            SVMModel = fitcsvm(SSVEP_power_C,labels,...
                'KernelFunction','linear','Standardize',true);
            LDAModel = fitcdiscr(SSVEP_power_C, labels);
            DTModel  = fitctree(SSVEP_power_C, labels);

            METHOD_PARAMS.SVMModel = SVMModel;
            METHOD_PARAMS.LDAModel = LDAModel;
            METHOD_PARAMS.DTModel  = DTModel;

            save('PARAMS.mat','EEG_PARAMS','RT_PARAMS','METHOD_PARAMS');
            disp('Calibration complete');
        end
        RT_reset;
    end

    % ---------- ONLINE / CALIBRATION DATA ----------
    if trial_on
        if strcmp(block_type, 'Game')
            SSVEP_Power = RT_SSVEP_noDSS(final_vec, EEG_PARAMS, METHOD_PARAMS);
            fb_out_send = predict(METHOD_PARAMS.SVMModel, SSVEP_Power);
            fwrite(fid2,fb_out_send, 'double');
            fseek(fid2, 0, 'bof');
            disp(fb_out_send);
        else
            % avg rerf
            eeg_chunk = vec(1:EEG_PARAMS.channels,:);   % all EEG
            eeg_chunk = eeg_chunk - mean(eeg_chunk,1); % CAR

            EEG_Data{tr} = cat(2, EEG_Data{tr}, vec(EEG_PARAMS.electrodes,:));
        end

        fprintf('%.2d\t%.5f\n',trig_value,ts);
    end

    AcquisitionInterrupt;
    if breakLoop
        break;
    end
end

%% Exit
fclose(fid2);
disp('Session ended');