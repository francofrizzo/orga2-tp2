#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "../tp2.h"
 
#define E 2.71828182845904523536
#define PI 3.14159265358979323846
#define FUNC_GAUSSIANA(sigma, radius, i, j) (1/(2 * PI * sigma * sigma)) * pow(E, ((radius - i) * (radius - i) + (radius - j) * (radius - j)) / (-2 * sigma * sigma))

float* matrizDeConvolucion (float sigma, int radius) {
    float* res = malloc((2 * radius + 1) * (2 * radius + 1) * 4);  // el 4 es porque son floats - by lu
    float (*res_matrix)[radius * 2 + 1] = (float (*)[radius * 2 + 1]) res;
	for (int i = 0; i < 2 * radius + 1; i ++) {
		for (int j = 0; j < 2 * radius + 1; j++) {
			res_matrix[i][j] = FUNC_GAUSSIANA(sigma, radius, i, j);
		}
	}
    return res;
}

void afectarPixel (unsigned char *src, unsigned char *dst, float* matConv, int l, int h, int radius, int cols) {
    unsigned char (*src_matrix)[cols*4] = (unsigned char (*)[cols*4]) src;
    unsigned char (*dst_matrix)[cols*4] = (unsigned char (*)[cols*4]) dst;
    float (*matConv_matrix)[radius * 2 + 1] = (float (*)[radius * 2 + 1]) matConv;

    double sumaAzul = 0;
    double sumaVerde = 0;
    double sumaRojo = 0;

    for(int i = 0; i <= 2 * radius; i++){
        for(int j = 0; j <= 2 * radius * 4; j = j + 4){
           sumaAzul = sumaAzul + src_matrix[l - radius + i][h - radius * 4 + j] * matConv_matrix[i][j / 4];
           sumaVerde = sumaVerde + src_matrix[l - radius + i][h - radius * 4 + j + 1] * matConv_matrix[i][j / 4];
           sumaRojo = sumaRojo + src_matrix[l - radius + i][h - radius * 4 + j + 2] * matConv_matrix[i][j / 4];
        }
    }

    dst_matrix[l][h + 0] = sumaAzul;
    dst_matrix[l][h + 1] = sumaVerde;
    dst_matrix[l][h + 2] = sumaRojo;
    dst_matrix[l][h + 3] = 255;
}

void blur_c (unsigned char *src, unsigned char *dst, int cols, int filas, float sigma, int radius) {
    //unsigned char (*src_matrix)[cols*4] = (unsigned char (*)[cols*4]) src;
    //unsigned char (*dst_matrix)[cols*4] = (unsigned char (*)[cols*4]) dst;

    if (radius < filas / 2 && radius < cols / 2) {
        float* matConv = matrizDeConvolucion(sigma, radius);
        // float (*res_matrix)[radius * 2 + 1] = (float (*)[radius * 2 + 1]) matConv;
        for (int l = radius; l <= filas - (radius + 1); l ++) {
            for (int h = radius * 4; h <= (cols - (radius + 1)) * 4; h = h + 4) {
                afectarPixel(src, dst, matConv, l, h, radius, cols);
            }
        }       
    }
}
