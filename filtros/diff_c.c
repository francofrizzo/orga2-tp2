// Versión de diff_c sin llamados funciones auxiliares

#include <stdlib.h>
#include <math.h>
#include "../tp2.h"

#define ABS_DIFF(a, b) (a > b ? a - b : b - a)
#define MAX(a, b) (a > b ? a : b)
#define MAX_3(a, b, c) MAX(MAX(a, b), c)

void diff_c (
    unsigned char *src,
    unsigned char *src_2,
    unsigned char *dst,
    int m, // columnas
    int n, // filas
    int src_row_size,
    int src_2_row_size,
    int dst_row_size
) {
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*src_2_matrix)[src_2_row_size] = (unsigned char (*)[src_2_row_size]) src_2;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < 4 * m; j = j + 4) {
            unsigned char b_diff = ABS_DIFF(src_matrix[i][j], src_2_matrix[i][j]);
            unsigned char g_diff = ABS_DIFF(src_matrix[i][j+1], src_2_matrix[i][j+1]);
            unsigned char r_diff = ABS_DIFF(src_matrix[i][j+2], src_2_matrix[i][j+2]);

            unsigned char diff = MAX_3(b_diff, g_diff, r_diff);

            dst_matrix[i][j] = diff;
            dst_matrix[i][j+1] = diff;
            dst_matrix[i][j+2] = diff;
            dst_matrix[i][j+3] = 255;
        }
    }
}
