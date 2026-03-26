function pnq = DSSGetPnq(epochs,freq,Fs)

dss_in = permute(epochs,[2,1,3]);
[c0, c1] = cog_bias_fft(dss_in, freq/Fs, Fs);
pnq = nt_dss0(c0, c1);

end