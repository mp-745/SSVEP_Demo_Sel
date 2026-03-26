function [CRinv,blkProd,xDim,T,d] = cog_getGPFAterms(params,T,latent_dim)

if ~exist('latent_dim','var')
    latent_dim = 1:size(params.C,2);
end

params.C = params.C(:,latent_dim);
params.covType = params.covType(latent_dim);
params.Fs = params.Fs(latent_dim);
params.freq = params.freq(latent_dim);
params.gamma = params.gamma(latent_dim);
params.a = params.a(latent_dim);
params.eps = params.eps(latent_dim);
params.coeff = params.coeff(latent_dim);

C = params.C;
d = params.d;
[yDim, xDim] = size(C);

% Precomputations
if params.notes.RforceDiagonal
    Rinv     = diag(1./diag(params.R));
    logdet_R = sum(log(diag(params.R)));
else
    Rinv     = inv(params.R);
    Rinv     = (Rinv+Rinv') / 2; % ensure symmetry
    logdet_R = logdet(params.R);
end
CRinv  = params.C' * Rinv;
CRinvC = CRinv * params.C;

% Overview:
% - Outer loop on each elt of Tu.
% - For each elt of Tu, find all trials with that length.
% - Do inference and LL computation for all those trials together.

[K_big, K_big_inv, logdet_K_big] = make_K_big(params, T);

% There are three sparse matrices here: K_big, K_big_inv, and CRinvC_inv.
% Choosing which one(s) to make sparse is tricky.  If all are sparse,
% code slows down significantly.  Empirically, code runs fastest if
% only K_big is made sparse.
%
% There are two problems with calling both K_big_inv and CRCinvC_big
% sparse:
% 1) their sum is represented by Matlab as a sparse matrix and taking
%    its inverse is more costly than taking the inverse of the
%    corresponding full matrix.
% 2) term2 has very few zero entries, but Matlab will represent it as a
%    sparse matrix.  This makes later computations with term2 ineffficient.

K_big = sparse(K_big);

blah        = cell(1, T);
[blah{:}]   = deal(CRinvC);
%CRinvC_big = blkdiag(blah{:});     % (xDim*T) x (xDim*T)
[invM, logdet_M] = invPerSymm(K_big_inv + blkdiag(blah{:}), xDim,...
    'offDiagSparse', true);

% Note that posterior covariance does not depend on observations,
% so can compute once for all trials with same T.
% xDim x xDim posterior covariance for each timepoint
Vsm = nan(xDim, xDim, T);
idx = 1: xDim : (xDim*T + 1);
for t = 1:T
    cIdx       = idx(t):idx(t+1)-1;
    Vsm(:,:,t) = invM(cIdx, cIdx);
end

% T x T posterior covariance for each GP
VsmGP = nan(T, T, xDim);
idx   = 0 : xDim : (xDim*(T-1));
for i = 1:xDim
    VsmGP(:,:,i) = invM(idx+i,idx+i);
end

% Compute blkProd = CRinvC_big * invM efficiently
% blkProd is block persymmetric, so just compute top half
Thalf   = ceil(T/2);
blkProd = zeros(xDim*Thalf, xDim*T);
idx     = 1: xDim : (xDim*Thalf + 1);
for t = 1:Thalf
    bIdx            = idx(t):idx(t+1)-1;
    blkProd(bIdx,:) = CRinvC * invM(bIdx,:);
end
blkProd = K_big(1:(xDim*Thalf), :) *...
    fillPerSymm(speye(xDim*Thalf, xDim*T) - blkProd, xDim, T);


end
