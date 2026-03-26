function METHOD_PARAMS = CdfEstimate(POWER,METHOD_PARAMS,RT_PARAMS,EEG_PARAMS,SAVE)

fig = figure;
set(fig,'Position',[0 0 1920 1080]);

min_len = min(cellfun('size',POWER.power,1));
for tr = 1:length(POWER.power)
    data(:,:,tr) = POWER.power{tr}(1:min_len,:);
end

data = smooth(data,RT_PARAMS.grouping_factor);
SSVEP_freq = EEG_PARAMS.SSVEP_freq;
LR = {'Left','Right'};

for lr = 1:length(LR)
    
    if lr == 1
       AT_idx = POWER.LeftFlick_T_idx; AA_idx = POWER.LeftFlick_D_idx; 
    else
       AT_idx = POWER.RightFlick_T_idx; AA_idx = POWER.RightFlick_D_idx; 
    end
    
    dataAT = cat(1,POWER.power{AT_idx});
    dataAA = cat(1,POWER.power{AA_idx});
    
    SSVEP_dist(lr) = fitdist(cat(1,dataAT(:,lr),dataAA(:,lr)),'kernel');
    
    subplot(2,4,(lr-1)*4+1);
    temp_AT = dataAT(:,lr);
    temp_AT(abs(zscore(temp_AT))>3) = []; 
    temp_AA = dataAA(:,lr);
    temp_AA(abs(zscore(temp_AA))>3) = []; 
    
    [~,T_bins] = hist([temp_AT(:);temp_AA(:)],50);
    T_bins = [T_bins(1)-T_bins(2)+T_bins(1) T_bins T_bins(end)+T_bins(2)-T_bins(1)];
    histogram(temp_AT,T_bins);
    hold on;
    histogram(temp_AA,T_bins);
    xlabel('SSVEP Power');
    title(sprintf('%d Hz %s Histogram',SSVEP_freq(1),LR{lr}));
    legend('AT','AA');
    
    subplot(2,4,(lr-1)*4+2);
    h(1) = cdfplot(dataAT(:,lr));
    hold on;
    h(2) = cdfplot(dataAA(:,lr));
    legend(h,{'AT','AA'});
    xlabel('SSVEP Power');ylabel('CDF');
    
    subplot(2,4,(lr-1)*4+3);
    pow_AT = squeeze(data(:,lr,AT_idx));
    pow_AA = squeeze(data(:,lr,AA_idx));
    
    plot_func(pow_AT,pow_AA);
    title('SSVEP Power Time-series');
            
    subplot(2,4,(lr-1)*4+4);
    cdf_AT = squeeze(cdf(SSVEP_dist(lr),data(:,lr,AT_idx)));
    cdf_AA = squeeze(cdf(SSVEP_dist(lr),data(:,lr,AA_idx)));
    
    plot_func(cdf_AT,cdf_AA)
    ylim([0 1]);
    title('SSVEP CDF Time-series');
    
end

suptitle(sprintf('SSVEP Power %s',METHOD_PARAMS.method));
saveas(fig,[SAVE.savepath sprintf('Hist_CDF_%dHz_%s_data_%s.png',SSVEP_freq(1),METHOD_PARAMS.method,SAVE.fname)]);

METHOD_PARAMS.fit_dist = SSVEP_dist;

end

function plot_func(pow_AT,pow_AA)

plot_data = [nanmean(pow_AT,2)',nanmean(pow_AA,2)'];
plot(plot_data,'k--','Linewidth',0.5);
hold on;
plot_data2 = [nanmean(pow_AT(:))*ones(1,size(pow_AT,1)),nanmean(pow_AA(:)*ones(1,size(pow_AA,1)))];
plot(plot_data2,'k-','Linewidth',2);
set(gca,'xticklabel',{[]});

end
