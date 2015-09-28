default rel
global _diff_asm2
global diff_asm2

section .data

section .text

; void diff_asm (
;     unsigned char *src,
;     unsigned char *src2,
;     unsigned char *dst,
;     int filas,
;     int cols
; )

_diff_asm2:
diff_asm2:

    ; rdi = src
    ; rsi = src2
    ; rdx = dst
    ; ecx = filas
    ; r8d = cols

    ret
