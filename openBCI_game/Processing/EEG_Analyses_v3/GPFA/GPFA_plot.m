function [] = GPFA_plot(GPFA_out,Fs,w,w_inv,kernels)

no_subplot = 4;
no_fig = ceil(size(GPFA_out,1)/no_subplot);

f=figure;
emo_plot_mt(nanmean(GPFA_out,3),Fs);

for i=1:no_fig
    fig = figure;
    set(fig,'Position',[0 0 1366 768]);
    for j=1:no_subplot
        dim_no = (i-1)*no_subplot + j;
        if dim_no > size(GPFA_out,1)
            break;
        end
        subplot(3,no_subplot,j);
        [s]=emo_plot_mt(nanmean(GPFA_out(dim_no,:,:),3),Fs);
        ymax = max(s);
        ax_1 = get(f,'CurrentAxes');ax_2 = ax_1;
        ratio = ymax/ax_2.YLim(2);
        if ratio>0.1
            ylim([0 ax_2.YLim(2)]);
        elseif ratio>0.01
            ylim([0 ax_2.YLim(2)/10]);
        else
            ylim([0 ax_2.YLim(2)/100]);
        end
        
        switch kernels{dim_no}.covType
            case 'cosine'
                title(sprintf('SSVEP %d Hz',kernels{dim_no}.freq(1)));
            case 'alpha'
                title(sprintf('Alpha %d Hz',kernels{dim_no}.freq(1)));
            case 'uniform'
                title(sprintf('Uniform %d Hz',kernels{dim_no}.freq(1)));
            case 'gauss'
                title('Gauss');
        end
        
        subplot(3,no_subplot,j+no_subplot);
        topoplot(w_inv(:,dim_no),'Biosemi_128_Cartesian_Default.sfp','electrodes','on','colormap','jet');title('Unmixing Matrix');
        cbar;
        colormap('jet');
        
        subplot(3,no_subplot,j+2*no_subplot);
        topoplot(w(:,dim_no),'Biosemi_128_Cartesian_Default.sfp','electrodes','on','colormap','jet');title('Mixing Matrix');
        cbar;
        colormap('jet');
                
    end
end

end