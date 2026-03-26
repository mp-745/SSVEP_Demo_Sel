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
maxBufferTime       = 1.0; % the inlet buffers samples for `maxBufferTime` seconds before clearing ie `maxBufferTime * Fs` no. of samples
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

init_params;
RT_reset;
InitSave;

%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

%% resolve a stream
disp('Resolving an EEG stream...');
%result = {};
%while isempty(result)
%    result = lsl_resolve_byprop(lib,'type','EEG');
%end

result = {};
while isempty(result)
    result = lsl_resolve_byprop( ...
        lib, 'name', 'UnicornRecorderDataLSLStream');
end

%% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1}, maxBufferTime);


%% Receive data
disp('Now receiving data...');
inlet.pull_chunk();

while true 
    % get data from the inlet
    [vec,ts] = inlet.pull_chunk();
    
    if size(vec, 2) == 0
        continue; end
    
    final_vec = [final_vec(:,size(vec,2)+1:end) vec(1:EEG_PARAMS.channels,:)];
    
    % Read triggers
    trig_value = fread(trig_fileID);
    fseek(trig_fileID, 0, 'bof');
    if isempty(trig_value)
        trig_value = 0;
    end
    
    % append final_vec_all
    final_vec_all = [final_vec_all [vec(1:EEG_PARAMS.channels,:); ones([1, size(vec,2)])*trig_value]];
    
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
            % Reshape recorded data
            Data{1} = cat(3,EEG_Data{1:2:length(EEG_Data)});
            sz = size(Data{1});
            Data{1} = reshape(Data{1},sz(1),EEG_PARAMS.Fs,sz(2)*sz(3)/EEG_PARAMS.Fs);
            RT_Data{1} = reshape(Data{1},sz(1),RT_PARAMS.ring_buffer_size,sz(2)*sz(3)/RT_PARAMS.ring_buffer_size);
            
            Data{2} = cat(3,EEG_Data{2:2:length(EEG_Data)});
            sz = size(Data{2});
            Data{2} = reshape(Data{2},sz(1),EEG_PARAMS.Fs,sz(2)*sz(3)/EEG_PARAMS.Fs);
            RT_Data{2} = reshape(Data{2},sz(1),RT_PARAMS.ring_buffer_size,sz(2)*sz(3)/RT_PARAMS.ring_buffer_size);
            
%             Data{3} = cat(3,EEG_Data{3:3:length(EEG_Data)});
%             sz = size(Data{3});
%             Data{3} = reshape(Data{3},sz(1),EEG_PARAMS.Fs,sz(2)*sz(3)/EEG_PARAMS.Fs);
%             RT_Data{3} = reshape(Data{3},sz(1),RT_PARAMS.ring_buffer_size,sz(2)*sz(3)/RT_PARAMS.ring_buffer_size);
            
            % Get the DSS Dimension(s)
%             for f = 1:length(EEG_PARAMS.SSVEP_freq)
%                 for trial_no = 1:size(Data{f},3)
%                    data2(:,:,trial_no) = RT_Preprocess(Data{f}(:,:,trial_no),EEG_PARAMS); 
%                 end
%                 pnq{f} = DSSGetPnq(data2,EEG_PARAMS.SSVEP_freq(f),EEG_PARAMS.Fs);
%                 [~,data_out_mean] = DSSEstComp(data2, pnq{f}, 1:num_DSS_comps);
%                 pnq{f} = SelectComp(data_out_mean,pnq{f},EEG_PARAMS.SSVEP_freq(f),EEG_PARAMS);
%             end
%             METHOD_PARAMS.pnq = pnq;
            
            % Get Power for each epoch
            for lr = 1:2
                for trial_no = 1:size(RT_Data{lr},3)
                    SSVEP_power_C((lr-1)*size(RT_Data{1},3)+trial_no,:) = RT_SSVEP_noDSS(RT_Data{lr}(:,:,trial_no),EEG_PARAMS,METHOD_PARAMS);
                    labels((lr-1)*size(RT_Data{1},3)+trial_no,1) = lr;
                end
            end
            
            % Train Classifier
%             SVMModel = fitcecoc(SSVEP_power_C,labels);
%             LDAModel = fitcdiscr(SSVEP_power_C, labels);
%             DTModel  = fitctree(SSVEP_power_C, labels);
%             
%             % Get prediction and save data
%             METHOD_PARAMS.SVMModel = SVMModel;
%             METHOD_PARAMS.LDAModel = LDAModel;
%             METHOD_PARAMS.DTModel = DTModel;
            
            SVMModel = fitcsvm(SSVEP_power_C,labels,'KernelFunction','linear','Standardize',true);
            LDAModel = fitcdiscr(SSVEP_power_C, labels);
            DTModel  = fitctree(SSVEP_power_C, labels);
            
%             figure;
%             scatter(SSVEP_power_C(labels == -1,1),SSVEP_power_C(labels == -1,2),'b'); hold on;
%             scatter(SSVEP_power_C(labels == 1,1),SSVEP_power_C(labels == 1,2),'r');
%             xlabel('Left SSVEP'); ylabel('Right SSVEP');

            METHOD_PARAMS.SVMModel = SVMModel;
            METHOD_PARAMS.LDAModel = LDAModel;
            METHOD_PARAMS.DTModel = DTModel;
            
            labels_out = predict(SVMModel,SSVEP_power_C);
            Acc = mean(labels_out == labels);
            
            csvm = crossval(METHOD_PARAMS.SVMModel);
            Acc2 = (1 - kfoldLoss(csvm));
            
            disp(Acc2);
            disp(Acc);
            disp(confusionmat(labels,labels_out));
            save('SVM_Out_1','labels','labels_out','SSVEP_power_C', 'RT_Data');
            
            fid1=fopen(acc_file_name,'w');
            fwrite(fid1,Acc,'double');
            fclose(fid1);
            
            save('PARAMS.mat','EEG_PARAMS','RT_PARAMS','METHOD_PARAMS');
            save('data.mat','Data') 
            save(save_fname, 'final_vec_all', 'EEG_PARAMS', 'METHOD_PARAMS', 'RT_PARAMS', 'RT_Data', 'SSVEP_power_C', 'Acc', 'num_DSS_comps', 'maxBufferTime', 'SSVEP_all', 'Subject');
            disp('Data has successfully been saved');
        end
        RT_reset;
    end
    
    % Stream Data if trial_on is true
    if trial_on 
        if strcmp(block_type, 'Game')
            SSVEP_Power = RT_SSVEP_noDSS(final_vec, EEG_PARAMS, METHOD_PARAMS);
            fb_out_send = predict(METHOD_PARAMS.SVMModel, SSVEP_Power);
            fwrite(fid2,fb_out_send, 'double');
            fseek(fid2, 0, 'bof');
            disp(fb_out_send);
%             SSVEP_all = [SSVEP_all;SSVEP_Power];
%             Classifier_out_all = [Classifier_out_all;fb_out_send];
        else
            % Collect data.. (arrives here when Calibrate -> trial start)
            % EEG_Data{tr} = cat(2,EEG_Data{tr},vec(:, 1:EEG_PARAMS.electrodes)'); % Use this when using pull_sample() ... `final_vec` would also need to be changed
            EEG_Data{tr} = cat(2, EEG_Data{tr}, vec(EEG_PARAMS.electrodes,:)); % Use this when using pull_chunk()
        end
        
        iter_count = iter_count + 1;
        
        %fprintf('%.2f\t',vec);
        fprintf('%.2d\t',trig_value);
        fprintf('%.5f\n',ts);
    end
    
    AcquisitionInterrupt;
    if breakLoop
        break;
    end
end

%% Plot power spectrum for averaged training data
PlotSSVEPPowers;

%% Exit message
fclose(fid2);
disp('Session ended');