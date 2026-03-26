function [c0,c1,c1T]=cog_bias_fft(x,freq,nfft,powerFlag)
if ~exist('powerFlag', 'var')
    powerFlag = 0;
end

if max(freq(:))>0.5; error('frequencies should be <= 0.5'); end
if nfft>size(x,1); error('nfft too large'); end

filt=zeros(round(nfft/2+0.5),1);

if size(freq,1)==1
    for k=1:size(freq,2)
        idx=round(freq(1,k)*nfft+0.5);
        filt(idx)=1;
    end
elseif size(freq,1)==2
    for k=1:size(freq,2)
        idx=round(freq(1,k)*nfft+0.5) : round(freq(2,k)*nfft+0.5);
        filt(idx)=1;
    end
else
    error('freq should have one or two rows');
end

if rem(nfft,2)==0
    filt=[filt;flipud(filt(2:end-1))];
else
    filt=[filt;flipud(filt(2:end))];
end

w=hanning(nfft);

[m,n,o]=size(x);
c0=zeros(n); c0T = zeros(n,n,o);
c1=zeros(n); c1T = zeros(n,n,o);
for j=1:o
    nframes=ceil((m-nfft/2)/(nfft/2));
    temp = x(:,:,j);
%     temp(isnan(temp)) = 0;
    temp = nt_demean(temp);
%     keyboard;
    c0T(:,:,j) = temp'*temp;
    tempc1 = zeros(n);
    for k=1:nframes
        idx=(k-1)*nfft/2;
        idx=min(idx,m-nfft);
        z=x(idx+1:idx+nfft,:,j);
        Z=fft(nt_vecmult(z,w));
        Z=nt_vecmult(Z,filt);
        tempc1=tempc1+real(Z'*Z);
    end
    c1T(:,:,j) = tempc1;
    if powerFlag == 1
        c1T(:,:,j) = tempc1/nframes;
    end
%     keyboard;
end
c0 = nanmean(c0T,3);
c1 = nanmean(c1T,3);
% keyboard;