function [] = PlotSpectrum(EPOCHS,SAVE)

epochs = EPOCHS.epochs;
Fs = EPOCHS.Fs;

fig = figure;
subplot(2,2,[1 2]);
emo_plot_mt(nanmean(epochs,3),Fs,[0 45]);
title('Raw Spectrum');
xlabel('Frequency'); ylabel('Power');

subplot(2,2,3);
emo_plot_mt(nanmean(epochs(:,:,EPOCHS.Left_idx),3),Fs,[0 45]);
title('Left Flickering Trials');
xlabel('Frequency'); ylabel('Power');

subplot(2,2,4);
emo_plot_mt(nanmean(epochs(:,:,EPOCHS.Right_idx),3),Fs,[0 45]);
title('Right Flickering Trials');
xlabel('Frequency'); ylabel('Power');
saveas(fig,[SAVE.savepath sprintf('raw_spect_%s.png',SAVE.fname)]);

end