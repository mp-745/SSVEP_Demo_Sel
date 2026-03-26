function [triggers] = cog_get_triggers(trigger_data)

max_val = 255;
trigger_data = trigger_data - min(trigger_data);
trigger_data = round(trigger_data * (max_val/max(trigger_data)));

trigger_diff = trigger_data(2:end) - trigger_data(1:end-1);
trigger_diff(trigger_diff < 0) = 0;

idx = find(trigger_diff > 0)+1;
triggers = [trigger_data(idx);idx]';

end

