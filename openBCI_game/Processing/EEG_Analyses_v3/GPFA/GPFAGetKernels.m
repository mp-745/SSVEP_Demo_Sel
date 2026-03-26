function kernels = GPFAGetKernels(Fs, SSVEP_freq, band_params, uniform_params, gauss)

SSVEP_ker = [];
for i=1:length(SSVEP_freq)
    SSVEP_ker(i).freq = [SSVEP_freq(i) 2*SSVEP_freq(i)];
    SSVEP_ker(i).coeff = [1 1];
end

band_ker = [];
for i=1:size(band_params,2)
    band_ker(i).freq = band_params(1,i);
    band_ker(i).sig = band_params(2,i);
end

uniform_ker = [];
for i=1:size(uniform_params,2)
    uniform_ker(i).freq = uniform_params(1,i);
    uniform_ker(i).sig = uniform_params(2,i);
end

no_of_rbf = gauss;

kernels = make_kernel_cell(Fs,SSVEP_ker,band_ker,uniform_ker,no_of_rbf);

end