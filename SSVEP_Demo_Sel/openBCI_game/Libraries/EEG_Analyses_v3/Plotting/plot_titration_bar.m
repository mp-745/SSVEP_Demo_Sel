function [p_vals] = plot_titration_bar(data,AT_idx,AA_idx)

cutoff = 2;
X = abs(zscore(data));

for i=1:size(X,2)
    idx{i} = find(X(:,i) > cutoff);
end

rejectTr = unique(cat(1,idx{:}));

AT_idx = setdiff(AT_idx,rejectTr);
AA_idx = setdiff(AA_idx,rejectTr);

data(rejectTr,:) = NaN;
% data = (data - min(data,[],1))./(max(data,[],1) - min(data,[],1));

Left_tr = data(AT_idx);
Right_tr = data(AA_idx);

plot_mean = [0 0];
plot_std = [0 0];
    
plot_mean = [plot_mean; [nanmedian(Left_tr), nanmedian(Right_tr)]];
plot_std = [plot_std; [nanstd(Left_tr)/sqrt(length(AT_idx)), nanstd(Right_tr)/sqrt(length(AA_idx))]];

h = barwitherr(plot_std, plot_mean);
set(gca,'XTickLabel',{''});

legend({'AT','AA'},'Location','best');

L_AT = Left_tr(:,1); 

%% bootstrap

p_vals = cog_bootstrap(Left_tr(:,1),Right_tr(:,1),10000,false,2);

end