% Codigo en Matlab 2022
% Autor Juan Guillermo Torres

clear all
clc
% Leo archivo csv y convierto a una tabla en Matlab
tabla = readtable('retornos_acciones.csv');


% Ventana deslizante con 100 datos
n=1; % fecha de incio, 
m=2; % columna de inicio, m=1 no aplica (es la fecha)
ventana=tabla([n:99+n],m);         % extraer datos tabla
ventana_mat=table2array(ventana);   % convierte tabla a matriz

% Retorno medio del activo en la ventana ventana_mat
rmedio=mean(ventana_mat);

% Calculo matriz de covarianza
sigma=cov(ventana_mat,ventana_mat);


% Organizo la matriz
A=[sigma -rmedio 1];

A = [4 1;1 3];
b = [9;1542];
% Calculo la solucion mediante complejos conjugados
x = conjugados(A, b);
% A*x=b


