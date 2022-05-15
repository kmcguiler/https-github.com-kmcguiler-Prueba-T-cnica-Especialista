function new_weights = inverseVarianceFcn(current_weights, pricesTT) 
% Inverse-variance portfolio allocation

assetReturns = pricesTT;
assetCov = cov(assetReturns{:,:});
new_weights = 1 ./ diag(assetCov);
new_weights = new_weights / sum(new_weights);

end