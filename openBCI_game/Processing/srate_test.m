clear all; close all; clc;

%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

%% resolve a stream
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG');
end

%% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1}, 1.0);

%%

% disp('Now receiving data...');
% while true
%     [vec,ts] = inlet.pull_sample();
%         fprintf('%.2f\t',vec);
%         fprintf('%.5f\n',ts);
% end

%% display data
% len_arr = [];
% disp('Now receiving data...');
% inlet.pull_chunk(); 
% while length(len_arr) ~= 120
%     vec_all = [];
%     tic;
%     while toc <=1
%         % get data from the inlet
%         [vec,ts] = inlet.pull_sample();
%         vec_all = [vec_all; vec];
%     end
%     %fprintf('%d', size(vec_all, 1));
%     
%     len_arr = [len_arr, size(vec_all, 1)];
% end


%% Pull Chunk Test
% len_vec = [];
% inlet.pull_chunk();
% tic; 
% while size(len_vec, 1) ~= 1800
%     if toc >= 1.0
%         [vec, ts] = inlet.pull_chunk(); 
%         len_vec = [len_vec; size(vec,2)];
%         tic;
%     end
% end

%% 
inlet.pull_chunk()
while true
    [vec, ts] = inlet.pull_sample();
    size(vec)
end