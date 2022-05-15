% Uso de Backtest con Matlab. 
% Este modulo se implementó en la version Matlab 2021, en versiones
% anteriores no funcionaria.
% Autor: Juan Guillermo Torres H.

% Limpiamos los datos
clear all
clc

% Leemos el archivo
Table = readtable('retornos_acciones.csv');
                                                % Tomo las primeras 5
                                                % empresas para dibujar
empresas = ["MMM","AOS","ABT","ABBV","ABMD","ACN","ATVI","ADM","ADBE","ADP"];
T_fig=Table(:,["Date" empresas]);
%Table=T_fig;

% Convertir formatos 
T = table2timetable(Table,'RowTimes','Date');   % Variables de tiempo
T_mat=table2array(T);                           % Manejo como Matriz



head(T)                                         % Ver la tabla

% plot(Table.Date, [Table.MMM Table.AOS Table.ABT Table.ABBV Table.ABMD]);
% title('Retorno de acciones vs tiempo')
% ylabel('Retorno por accion USD')
% xlabel('Fecha')
% legend("MMM","AOS","ABT","ABBV","ABMD") 
% grid on

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
strategyNames = {'Equiprobable', 'Max tasa Sharpe', 'Varianza inversa', 'Optimizacion Markowitz','Optimizacion Robusta'};
assetSymbols = T.Properties.VariableNames;
initialWeights = [equalWeight_initial(:), maxSharpeRatio_initial(:), inverseVariance_initial(:), markowitz_initial(:), robustOptim_initial(:)];
% heatmap(strategyNames, assetSymbols, initialWeights, 'title','Asignacion inicial de las acciones','Colormap', parula);



% --------------------------------------------------------------------------
% Rebalance each 12 days
rebalFreq = 100;

% Set the rolling lookback window 
lookback  = [100 700];

% Costo de transacción = 0.5% of amount traded
transactionsFixed = 0.005;

% Customize the transaction costs using a function. See the
% variableTransactionCosts function below for an example.
transactionsVariable = @variableTransactionCosts;

% The first two strategies use fixed transaction costs. The equal-weighted
% strategy does not require a lookback window of trailing data, as its
% allocation is fixed.
strat1 = backtestStrategy('Equiprobable', @equalWeightFcn,...
    'RebalanceFrequency', rebalFreq,...
    'LookbackWindow', 0,...
    'TransactionCosts', transactionsFixed,...
    'InitialWeights', equalWeight_initial);

strat2 = backtestStrategy('Max_tasa_Sharpe', @maxSharpeRatioFcn,...
    'RebalanceFrequency', rebalFreq,...
    'LookbackWindow', lookback,...
    'TransactionCosts', transactionsFixed,...
    'InitialWeights', maxSharpeRatio_initial);

% Use variable transaction costs for the remaining strategies.
strat3 = backtestStrategy('Varianza_inversa', @inverseVarianceFcn,...
    'RebalanceFrequency', rebalFreq,...
    'LookbackWindow', lookback,...
    'TransactionCosts', @variableTransactionCosts,...
    'InitialWeights', inverseVariance_initial);
strat4 = backtestStrategy('Optimizacion_Markowitz', @markowitzFcn,...
    'RebalanceFrequency', rebalFreq,...
    'LookbackWindow', lookback,...
    'TransactionCosts', transactionsFixed,...
    'InitialWeights', markowitz_initial);
strat5 = backtestStrategy('Optimizacion_Robusta', @robustOptimFcn,...
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
backtester = runBacktest(backtester, T, 'End', warmupPeriod)
summaryByStrategies = summary(backtester)

equityCurve(backtester)


% Transpose the summary table to plot the metrics.
summaryByMetrics = rows2vars(summaryByStrategies);
summaryByMetrics.Properties.VariableNames{1} = 'Strategy'


% Compare the strategy turnover.
names = [backtester.Strategies.Name];
nameLabels = strrep(names,'_',' ');
plot(backtester.Returns.Time,backtester.Returns.Equiprobable)
hold on
plot(backtester.Returns.Time,backtester.Returns.Max_tasa_Sharpe)
hold on
plot(backtester.Returns.Time,backtester.Returns.Varianza_inversa)
hold on
plot(backtester.Returns.Time,backtester.Returns.Optimizacion_Markowitz)
hold on
plot(backtester.Returns.Time,backtester.Returns.Optimizacion_Robusta)
%bar(summaryByMetrics.AverageTurnover)
title('Comportamiento de los retornos')
ylabel('Retorno USD')
%set(gca,'xticklabel',nameLabels)
legend([strategies.Name]);


