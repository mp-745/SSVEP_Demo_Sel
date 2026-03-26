SSVEP_power = [];
SSVEP_buff = zeros(2,RT_PARAMS.grouping_factor);
CDF_val = [NaN,NaN];

fb_out_send = [0,0];
cnt=1;

SSVEP_power_all = [];
ring_buffer_all = [];

try
    fid1=fopen(feedback_file_name,'w');
    fwrite(fid1,[0,0],'double');
    fclose(fid1);
catch
end
