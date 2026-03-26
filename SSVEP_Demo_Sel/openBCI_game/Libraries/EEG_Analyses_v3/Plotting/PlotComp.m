function [] = PlotComp(data, W, AT_idx, AA_idx, freq, Col, EEG_PARAMS, varargin)

% data = Samples X Trials

title_str = '';
BiosemiLoc = 'Biosemi_128_Cartesian_Default.sfp';

assignopts(who,varargin{:});

Fs = EEG_PARAMS.Fs;
Time = size(data,2)/Fs; X = (1:size(data,1))/Fs;

data_AT = data(:,AT_idx);
data_AA = data(:,AA_idx);

h(1) = subplot(5,2*Col(1),2*(Col(2)-1)+1);
emo_plot_mt(nanmean(data_AT,2),Fs);
title(sprintf('%s AT Spectrum (%d Hz)',title_str,freq));
h(2) = subplot(5,2*Col(1),2*(Col(2)-1)+2);
emo_plot_mt(nanmean(data_AA,2),Fs);
title(sprintf('%s AA Spectrum (%d Hz)',title_str,freq));
linkaxes(h);

h(1) = subplot(5,2*Col(1), 2*Col(1) + 2*(Col(2)-1) + 1);
emo_plot_mt_err(data_AT', Fs);
title('AT Spectrum');
h(2) = subplot(5,2*Col(1), 2*Col(1) + 2*(Col(2)-1) + 2);
emo_plot_mt_err(data_AA', Fs);
title('AA Spectrum');
linkaxes(h);

h(1) = subplot(5,2*Col(1), 4*Col(1) + 2*(Col(2)-1) + 1);
plot(X, nanmean(data_AT,2));
h(2) = subplot(5,2*Col(1), 4*Col(1) + 2*(Col(2)-1) + 2);
plot(X, nanmean(data_AA,2));
linkaxes(h);

params = EEG_PARAMS.params;
params.fpass = freq;
for tr = 1:size(data,2)
    Power(tr) = mtspectrumc(data(:,tr),params)/Time;
end

h(1) = subplot(5,2*Col(1), 6*Col(1) + 2*(Col(2)-1) + 1);
p_val = plot_titration_bar(Power',AT_idx,AA_idx);
title(sprintf('Median of SSVEP Power across Trials (p = %.4f)',p_val));
h(2) = subplot(5,2*Col(1), 8*Col(1) + 2*(Col(2)-1) + 1);
g = bar([0 0;mtspectrumc(nanmean(data(:,AT_idx),2),params)/Time,...
    mtspectrumc(nanmean(data(:,AA_idx),2),params)/Time]);
set(gca,'XTickLabel',{''});
legend({'AT','AA'},'Location','best');
title('SSVEP Power of mean of Trials');

subplot(5,2*Col(1), 6*Col(1) + 2*(Col(2)-1) + 2);
topoplot(W{1},BiosemiLoc,'electrodes','on','colormap','jet');title('Unmixing Matrix');
cbar;  % plot a colorbar
colormap('jet');
subplot(5,2*Col(1), 8*Col(1) + 2*(Col(2)-1) + 2);
topoplot(W{2},BiosemiLoc,'electrodes','on','colormap','jet');title('Mixing Matrix');
cbar;  % plot a colorbar
colormap('jet');

end