function [X,C,c_factor] = cog_GPFA_normalize(X,C,method)

if nargin == 2
    method = 'Max';
end

[Y_dim,X_dim] = size(C); 
[x_dim,n,m] = size(X);

if x_dim ~= X_dim
    error('X dim is wrong!!');
end

if strcmp(method,'SumSq')

for i=1:X_dim
    c_factor(i) = sum(C(:,i).^2); 
    C(:,i) = C(:,i)/c_factor(i);
    X(i,:,:) = X(i,:,:)*c_factor(i);
end

elseif strcmp(method,'Max')

for i=1:X_dim
    c_factor(i) = max(abs(C(:,i))); 
    C(:,i) = C(:,i)/c_factor(i);
    X(i,:,:) = X(i,:,:)*c_factor(i);
end

end
    
    
end