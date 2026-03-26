function [power_ch] = emo_plot_fft( arr,Fs )

%   data in ch X samples X trials
power_ch = zeros(size(arr,1),size(arr,2));

if ndims(arr)<=2
    for i=1:size(arr,1)
        spect=abs(fft(arr(i,:)));
        plot((0:length(spect)/2-1)*Fs/(length(spect)),spect((1:length(spect)/2)));
        hold on;
    end
else
    for i=1:size(arr,1)
        for j=1:size(arr,3)
            temp(:,j)=fft(arr(i,:,j));
        end
        spect = mean(abs(temp),2);
    power = spect/size(arr,3);
    power_ch(i,:)=power;
    plot((0:length(power)/2-1)*Fs/(length(power)),power((1:length(power)/2)));
    hold on;
    end
    
end


end