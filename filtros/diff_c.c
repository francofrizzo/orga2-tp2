
#include <stdlib.h>
#include <math.h>
#include "../tp2.h"

unsigned char abs_diff (unsigned char a, unsigned char b) {
	return a > b ? a - b : b - a;
}

unsigned char max_3 (unsigned char a, unsigned char b, unsigned char c) {
	unsigned char res = a > b ? a : b;
	res = res > c ? res : c;
	return res;
}

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

	// Versión sin funciones auxiliares

	// for (int i = 0; i < n; i++) {
	// 	for (int j = 0; j < 4 * m; j = j + 4) {
	// 		unsigned char b_diff = src_matrix[i][j] > src_2_matrix[i][j] ?
	// 			src_matrix[i][j] - src_2_matrix[i][j] :
	// 			src_2_matrix[i][j] - src_matrix[i][j];
	// 		unsigned char g_diff = src_matrix[i][j+1] > src_2_matrix[i][j+1] ?
	// 			src_matrix[i][j+1] - src_2_matrix[i][j+1] :
	// 			src_2_matrix[i][j+1] - src_matrix[i][j+1];
	// 		unsigned char r_diff = src_matrix[i][j+2] > src_2_matrix[i][j+2] ?
	// 			src_matrix[i][j+2] - src_2_matrix[i][j+2] :
	// 			src_2_matrix[i][j+2] - src_matrix[i][j+2];

	// 		unsigned char diff = b_diff > g_diff ? b_diff : g_diff;
	// 		diff = diff > r_diff ? diff : r_diff;

	// 		dst_matrix[i][j] = diff;
	// 		dst_matrix[i][j+1] = diff;
	// 		dst_matrix[i][j+2] = diff;
	// 		dst_matrix[i][j+3] = 255;
	// 	}
	// }

	// Usando funciones auxiliares

	for (int i = 0; i < n; i++) {
		for (int j = 0; j < 4 * m; j = j + 4) {
			unsigned char b_diff = abs_diff(src_matrix[i][j], src_2_matrix[i][j]);
			unsigned char g_diff = abs_diff(src_matrix[i][j+1], src_2_matrix[i][j+1]);
			unsigned char r_diff = abs_diff(src_matrix[i][j+2], src_2_matrix[i][j+2]);

			unsigned char diff = max_3(b_diff, g_diff, r_diff);

			dst_matrix[i][j] = diff;
			dst_matrix[i][j+1] = diff;
			dst_matrix[i][j+2] = diff;
			dst_matrix[i][j+3] = 255;
		}
	}

}
