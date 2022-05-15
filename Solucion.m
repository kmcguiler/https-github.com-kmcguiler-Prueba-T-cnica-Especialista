% Uso de Backtest con Matlab. 
% Este modulo se implementó en la version Matlab 2021, en versiones
% anteriores no funcionaria.
% Autor: Juan Guillermo Torres H.

% Limpiamos los datos
clear all
clc

% Leemos el archivo
Table = readtable('retornos_acciones.csv');
%Table.AMAT(121) = 0.00001;
%Table= removevars(Table,{'AMAT'});


% Convertir formatos 
T = table2timetable(Table,'RowTimes','Date');   % Variables de tiempo
T_mat=table2array(T);                           % Manejo como Matriz

                                                % Tomo las primeras 5
                                                % empresas para dibujar
empresas = ["MMM","AOS","ABT","ABBV","ABMD"];
T_fig=Table(:,["Date" empresas]);

head(T)                                         % Ver la tabla

plot(Table.Date, [Table.MMM Table.AOS Table.ABT Table.ABBV Table.ABMD]);
title('Retorno de acciones vs tiempo')
ylabel('Retorno por accion USD')
xlabel('Fecha')
legend("MMM","AOS","ABT","ABBV","ABMD") 
grid on

% Tamaños de la tabla
numSample = size(T.Variables, 1);
numAssets = size(T.Variables, 2);
table(numSample, numAssets)

warmupPeriod = 100; % Amplitud de la ventana de tiempo

% --------------------------------------------------------------------
% No current weights (100% cash position).
current_weights = zeros(1,numAssets);

% Warm-up partition of data set timetable.
warmupTT = T(1:warmupPeriod,:);

% Configuro las diferentes estrategias de inversion
% A todos les asigna el mismo peso = 0.02 = 1/50
equalWeight_initial     = equalWeightFcn(current_weights,warmupTT);
maxSharpeRatio_initial  = maxSharpeRatioFcn(current_weights,warmupTT);
inverseVariance_initial = inverseVarianceFcn(current_weights,warmupTT);
markowitz_initial       = markowitzFcn(current_weights,warmupTT);
robustOptim_initial     = robustOptimFcn(current_weights,warmupTT);


% Visualizo los pesos de las estrategias iniciales
strategyNames = {'Equiprobable', 'Max tasa Sharpe', 'Varianza inversa', 'Optimizacion Markowitz','Optimizacion Robusta.'};
assetSymbols = T.Properties.VariableNames;
initialWeights = [equalWeight_initial(:), maxSharpeRatio_initial(:), inverseVariance_initial(:), markowitz_initial(:), robustOptim_initial(:)];
heatmap(strategyNames, assetSymbols, initialWeights, 'title','Asignacion inicial de las acciones','Colormap', parula);



% --------------------------------------------------------------------------
% Rebalance approximately every 1 month (252 / 12 = 21).
rebalFreq = 12;

% Set the rolling lookback window to be at least 40 days and at most 126
% days (about 6 months).
lookback  = [100 100];

% Use a fixed transaction cost (buy and sell costs are both 0.5% of amount
% traded).
transactionsFixed = 0.005;

% Customize the transaction costs using a function. See the
% variableTransactionCosts function below for an example.
transactionsVariable = @variableTransactionCosts;

% The first two strategies use fixed transaction costs. The equal-weighted
% strategy does not require a lookback window of trailing data, as its
% allocation is fixed.
strat1 = backtestStrategy('Equal Weighted', @equalWeightFcn,...
    'RebalanceFrequency', rebalFreq,...
    'LookbackWindow', 0,...
    'TransactionCosts', transactionsFixed,...
    'InitialWeights', equalWeight_initial);

strat2 = backtestStrategy('Max Sharpe Ratio', @maxSharpeRatioFcn,...
    'RebalanceFrequency', rebalFreq,...
    'LookbackWindow', lookback,...
    'TransactionCosts', transactionsFixed,...
    'InitialWeights', maxSharpeRatio_initial);

% Use variable transaction costs for the remaining strategies.
strat3 = backtestStrategy('Inverse Variance', @inverseVarianceFcn,...
    'RebalanceFrequency', rebalFreq,...
    'LookbackWindow', lookback,...
    'TransactionCosts', @variableTransactionCosts,...
    'InitialWeights', inverseVariance_initial);
strat4 = backtestStrategy('Markowitz Optimization', @markowitzFcn,...
    'RebalanceFrequency', rebalFreq,...
    'LookbackWindow', lookback,...
    'TransactionCosts', transactionsFixed,...
    'InitialWeights', markowitz_initial);
strat5 = backtestStrategy('Robust Optimization', @robustOptimFcn,...
    'RebalanceFrequency', rebalFreq,...
    'LookbackWindow', lookback,...
    'TransactionCosts', transactionsFixed,...
    'InitialWeights', robustOptim_initial);

% Aggregate the strategy objects into an array.
strategies = [strat1, strat2, strat3, strat4, strat5];

% --------------------------------------------------------------------------
% Risk-free rate is 1% annualized
annualRiskFreeRate = 0.01;

% Create the backtesting engine object
backtester = backtestEngine(strategies, 'RiskFreeRate', annualRiskFreeRate)
backtester = runBacktest(backtester, T, 'Start', warmupPeriod)
summaryByStrategies = summary(backtester)

equityCurve(backtester)


% Transpose the summary table to plot the metrics.
summaryByMetrics = rows2vars(summaryByStrategies);
summaryByMetrics.Properties.VariableNames{1} = 'Strategy'


% Compare the strategy turnover.
names = [backtester.Strategies.Name];
nameLabels = strrep(names,'_',' ');
bar(summaryByMetrics.AverageTurnover)
title('Average Turnover')
ylabel('Daily Turnover (%)')
set(gca,'xticklabel',nameLabels)