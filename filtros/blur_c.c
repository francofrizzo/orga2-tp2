#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "../tp2.h"

 
#define e 2.71828182845904523536
#define M_PI 3.14159265358979323846


double funcionGaussiana(float sigma, int radius, int i, int j) {

return (1/(2 * M_PI * sigma * sigma)) * pow(e, ((radius - i) * (radius - i) + (radius - j) * (radius - j)) / (-2 * sigma * sigma));
}

float* matrizDeConvolucion(float sigma, int radius) {
float* res = malloc (2 * r + 1) * (2 * r + 1) * 4; //el 4 es porque son floats
float (*res_matrix)[r * 2 + 1] = (float (*)[r * 2 + 1]) res;
	for(int i = 0; i < 2 * r + 1; i ++) {
		for (int j = 0; j < 2 * r + 1; j++) {
			res[i][j] = funcionGaussiana(sigma, radius, i, j);
		}
	}
return res;
}




void blur_c (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    float sigma,
    int radius)
{
    unsigned char (*src_matrix)[cols*4] = (unsigned char (*)[cols*4]) src;
    unsigned char (*dst_matrix)[cols*4] = (unsigned char (*)[cols*4]) dst;

}
