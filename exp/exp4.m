% Procesado de los datos
[diff_c_x, diff_c_y, diff_c_e, diff_c_cant] = leer_datos('exp4/data-diff-c.txt');
[diff_c2_x, diff_c2_y, diff_c2_e, diff_c2_cant] = leer_datos('exp4/data-diff-c2.txt');
[blur_asm_x, blur_asm_y, blur_asm_e, blur_asm_cant] = leer_datos('exp4/data-blur-asm.txt');
[blur_asm2_x, blur_asm2_y, blur_asm2_e, blur_asm2_cant] = leer_datos('exp4/data-blur-asm2.txt');

% Impresión de los datos
mkdir('resultados');
file = fopen('resultados/exp4.txt', 'w');
formato = '  %18u    %16.2f    %16.2f\n';
encabezado= '    Tamaño de imagen     Tiempo empleado     Desvío estándar\n';
fprintf(file, 'Experimento 1\n');
fprintf(file, '\n  Filtro: diff   Implementación: C    Imágenes: phoebe1, phoebe2   Cant. muestras: %u\n', diff_c_cant);
fprintf(file, encabezado);
fprintf(file, formato, [diff_c_x'; diff_c_y'; diff_c_e']);
fprintf(file, '\n  Filtro: diff   Implementación: C2    Imágenes: phoebe1, phoebe2   Cant. muestras: %u\n', diff_c2_cant);
fprintf(file, encabezado);
fprintf(file, formato, [diff_c2_x'; diff_c2_y'; diff_c2_e']);
fprintf(file, '\n  Filtro: blur   Implementación: ASM    Imagen: phoebe1   Cant. muestras: %u\n', blur_asm_cant);
fprintf(file, encabezado);
fprintf(file, formato, [blur_asm_x'; blur_asm_y'; blur_asm_e']);
fprintf(file, '\n  Filtro: blur   Implementación: ASM2    Imagen: phoebe1   Cant. muestras: %u\n', blur_asm2_cant);
fprintf(file, encabezado);
fprintf(file, formato, [blur_asm2_x'; blur_asm2_y'; blur_asm2_e']);
fclose(file);

% Creación de los gráficos
filetype='-dpng';
mkdir('graficos');
figure;

hold on;
h = errorbar(diff_c_x, diff_c_y, diff_c_e);
errorbar(diff_c2_x, diff_c2_y, diff_c2_e);
hold off;
set(get(h, 'Parent'), 'YScale', 'log');
set(get(h, 'Parent'), 'XScale', 'log');
print('graficos/exp4-diff-c_vs_c2', filetype);

clf;
hold on;
h = errorbar(blur_asm_x, blur_asm_y, blur_asm_e);
errorbar(blur_asm2_x, blur_asm2_y, blur_asm2_e);
hold off;
set(get(h, 'Parent'), 'YScale', 'log');
set(get(h, 'Parent'), 'XScale', 'log');
print('graficos/exp4-blur-asm_vs_asm2', filetype);
