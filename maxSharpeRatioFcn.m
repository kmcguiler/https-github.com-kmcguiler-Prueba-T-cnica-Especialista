function new_weights = maxSharpeRatioFcn(current_weights, pricesTT)
% Mean-variance portfolio allocation

nAssets = size(pricesTT, 2);
%assetReturns = tick2ret(pricesTT);
%assetReturns1=table2array(assetReturns);       

% Manejo como Matriz
% Max 25% into a single asset (including cash)
p = Portfolio('NumAssets',nAssets,...
    'LowerBound',0,'UpperBound',0.1,...
    'LowerBudget',1,'UpperBudget',1);
p = estimateAssetMoments(p, pricesTT);
new_weights = estimateMaxSharpeRatio(p);

end