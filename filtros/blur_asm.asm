default rel
global _blur_asm
global blur_asm


section .data



section .text
;void blur_asm    (unsigned char *src, unsigned char *dst, int filas, int cols, float sigma, int radius)

_blur_asm:
blur_asm:
mov r9, rcx ; r9= filas/2
div r9, 2
cmp r9, r8
jl .seVaDeRangoElRadio ;si radio > filas/2 no se puede

mov r9, rdx ; r9= columnas/2
div r9, 2
cmp r9, r8
jl .seVaDeRangoElRadio ;si radio > filas/2 no se puede

;hasta aca tenemos el primer if



    ret
