function [p_val] = cog_bootstrap(set1,set2,numIter,plot_flag,mean_median)

if size(set1,2)~=1 || size(set2,2)~=1
    error('Inputs should be 1D (column)');
end

if ~exist('mean_median','var')
    mean_median = 1;
end

if mean_median == 1
    actual_result = nanmean(set1) - nanmean(set2);
else
    actual_result = nanmedian(set1) - nanmedian(set2);
end

combined_set = cat(1,set1,set2);

for i=1:numIter
    combined_set = shuffle(combined_set);
    bs_set1 = combined_set(1:length(set1)); bs_set2 = combined_set(length(set1)+1:end);
    if mean_median == 1
        bs_result(i) = nanmean(bs_set1) - nanmean(bs_set2);
    else
        bs_result(i) = nanmedian(bs_set1) - nanmedian(bs_set2);
    end
end

p_val = sum(bs_result>actual_result)/numIter;

if plot_flag
    histogram(bs_result);
    hold on;
    h = vline(actual_result);
    set(h,'LineWidth',2,'Color',[0 0 0],'LineStyle','-');
end

end