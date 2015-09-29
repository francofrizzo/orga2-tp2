% Procesado de los datos
[blur_c_x, blur_c_y, blur_c_e, blur_c_cant] = leer_datos('exp2/data-blur-c.txt');
[blur_asm_x, blur_asm_y, blur_asm_e, blur_asm_cant] = leer_datos('exp2/data-blur-asm.txt');

% Impresión de los datos
mkdir('resultados');
file = fopen('resultados/exp2.txt', 'w');
formato = '  %8u    %16.2f    %16.2f\n';
encabezado= '     Radio     Tiempo empleado     Desvío estándar\n';
fprintf(file, 'Experimento 2\n');
fprintf(file, '\n  Implementación: C   Imagen: phoebe1   Sigma: 5   Cant. muestras: %u\n', blur_c_cant);
fprintf(file, encabezado);
fprintf(file, formato, [blur_c_x'; blur_c_y'; blur_c_e']);
fprintf(file, '\n  Implementación: ASM   Imagen: phoebe1   Sigma: 5   Cant. muestras: %u\n', blur_asm_cant);
fprintf(file, encabezado);
fprintf(file, formato, [blur_asm_x'; blur_asm_y'; blur_asm_e']);
fclose(file);

% Creación de los gráficos
filetype='-dpng';
mkdir('graficos');
figure;

hold on;
errorbar(blur_c_x, blur_c_y, blur_c_e, 'r');
errorbar(blur_asm_x, blur_asm_y, blur_asm_e);
xlabel('Radio','FontSize',12);
ylabel('Tiempo de ejecucion en ciclos de clock','FontSize',12);
legend('Implementacion en C','Implementacion en ensamblador');
hold off;
print('graficos/exp2-tiempo_segun_radio', filetype);
