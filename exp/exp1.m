[diff_asm_x, diff_asm_y, diff_asm_e] = leer_datos('exp1/data-diff-asm.txt')
[diff_c_x, diff_c_y, diff_c_e] = leer_datos('exp1/data-diff-c.txt')

figure
hold on
errorbar(diff_c_x, diff_c_y, diff_c_e)
pause
errorbar(diff_asm_x, diff_asm_y, diff_asm_e)
pause
