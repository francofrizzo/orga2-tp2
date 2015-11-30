% Procesado de los datos
[diff_c_x, diff_c_y, diff_c_e, diff_c_cant] = leer_datos('exp1/data-diff-c.txt');
[diff_asm_x, diff_asm_y, diff_asm_e, diff_asm_cant] = leer_datos('exp1/data-diff-asm.txt');
[blur_c_x, blur_c_y, blur_c_e, blur_c_cant] = leer_datos('exp1/data-blur-c.txt');
[blur_asm_x, blur_asm_y, blur_asm_e, blur_asm_cant] = leer_datos('exp1/data-blur-asm.txt');

diff_c_tpp = diff_c_y ./ diff_c_x;
diff_asm_tpp = diff_asm_y ./ diff_asm_x;
blur_c_tpp = blur_c_y ./ blur_c_x;
blur_asm_tpp = blur_asm_y ./ blur_asm_x;

% Impresión de los datos
mkdir('resultados');
file = fopen('resultados/exp1.txt', 'w');
formato = '  %18u    %16.2f    %16.2f    %16.2f\n';
encabezado= '    Tamaño de imagen     Tiempo empleado     Tiempo por píxel    Desvío estándar\n';
fprintf(file, 'Experimento 1\n');
fprintf(file, '\n  Filtro: diff   Implementación: C    Imágenes: phoebe1, phoebe2   Cant. muestras: %u\n', diff_c_cant);
fprintf(file, encabezado);
fprintf(file, formato, [diff_c_x'; diff_c_y'; diff_c_tpp'; diff_c_e']);
fprintf(file, '\n  Filtro: diff   Implementación: ASM    Imágenes: phoebe1, phoebe2   Cant. muestras: %u\n', diff_asm_cant);
fprintf(file, encabezado);
fprintf(file, formato, [diff_asm_x'; diff_asm_y'; diff_asm_tpp'; diff_asm_e']);
fprintf(file, '\n  Filtro: blur   Implementación: C    Imagen: phoebe1   Cant. muestras: %u\n', blur_c_cant);
fprintf(file, encabezado);
fprintf(file, formato, [blur_c_x'; blur_c_y'; blur_c_tpp'; blur_c_e']);
fprintf(file, '\n  Filtro: blur   Implementación: ASM    Imagen: phoebe1   Cant. muestras: %u\n', blur_asm_cant);
fprintf(file, encabezado);
fprintf(file, formato, [blur_asm_x'; blur_asm_y'; blur_asm_tpp'; blur_asm_e']);
fclose(file);

% Creación de los gráficos
filetype='-dpng';
mkdir('graficos');
figure;

hold on;
h = errorbar(diff_c_x, diff_c_y, diff_c_e, 'r');
errorbar(diff_asm_x, diff_asm_y, diff_asm_e);
xlabel('Tamano de imagen','FontSize',12);
ylabel('Tiempo de ejecucion en ciclos de clock','FontSize',12);
legend('Implementacion en C','Implementacion en ensamblador','Location','northwest');
hold off;
set(get(h, 'Parent'), 'YScale', 'log');
set(get(h, 'Parent'), 'XScale', 'log');
print('graficos/exp1-diff-c_vs_asm', filetype);

clf;
hold on;
h = errorbar(blur_c_x, blur_c_y, blur_c_e, 'r');
errorbar(blur_asm_x, blur_asm_y, blur_asm_e);
xlabel('Tamano de imagen','FontSize',12);
ylabel('Tiempo de ejecucion en ciclos de clock','FontSize',12);
legend('Implementacion en C','Implementacion en ensamblador','Location','northwest');
hold off;
set(get(h, 'Parent'), 'YScale', 'log');
set(get(h, 'Parent'), 'XScale', 'log');
print('graficos/exp1-blur-c_vs_asm', filetype);

clf;
hold on;
h = plot(diff_c_x, diff_c_tpp, 'r');
plot(diff_asm_x, diff_asm_tpp);
xlabel('Tamano de imagen','FontSize',12);
ylabel('Tiempo de ejecucion por pixel en ciclos de clock','FontSize',12);
legend('Implementacion en C','Implementacion en ensamblador');
hold off;
set(get(h, 'Parent'), 'XScale', 'log');
print('graficos/exp1-diff-tiempo_por_pixel', filetype);

clf;
hold on;
h = plot(blur_c_x, blur_c_tpp, 'r');
plot(blur_asm_x, blur_asm_tpp);
xlabel('Tamano de imagen','FontSize',12);
ylabel('Tiempo de ejecucion por pixel en ciclos de clock','FontSize',12);
legend('Implementacion en C','Implementacion en ensamblador','Location','northwest');
hold off;
set(get(h, 'Parent'), 'XScale', 'log');
print('graficos/exp1-blur-tiempo_por_pixel', filetype);
