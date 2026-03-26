function out_struct = InitRtParams(Fs)

ring_buffer_time = 0.5; %enter value in seconds
ring_buffer_size = round(Fs*ring_buffer_time);
packet_size = 1;
grouping_factor = 8;

%% Make struct

vars  = who;

for i = 1:length(vars)
    out_struct.(vars{i}) =  eval(vars{i});
end

end