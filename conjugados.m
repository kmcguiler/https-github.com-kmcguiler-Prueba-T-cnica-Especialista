function x = conjugados(A, b)

% Input
% Matriz A
% Matriz b

% Usamos una tolerancia de 10^-6
% Usamos el # de iteraciones max = 100

% A = [4 1;1 3];
% b = [1;2];

% starts conjugate gradient method
x = cgs(A,b,1e-6,100);

end