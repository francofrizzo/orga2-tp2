default rel
global _diff_asm
global diff_asm

section .data

section .text
    mask_r_to_bgr: db 0x02, 0x02, 0x02, 0x03, 0x06, 0x06, 0x06, 0x07, 0x0a, 0x0a, 0x0a, 0x0b, 0x0e, 0x0e, 0x0e, 0x0f
    mask_alpha_to_ones: db 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0xff
    mask_alpha_to_zeroes: db 0xff, 0xff, 0xff, 0x00, 0xff, 0xff, 0xff, 0x00, 0xff, 0xff, 0xff, 0x00, 0xff, 0xff, 0xff, 0x00

;void diff_asm    (
	;unsigned char *src,
    ;unsigned char *src2,
	;unsigned char *dst,
	;int filas,
	;int cols)

_diff_asm:
diff_asm:

    ; rdi = src
    ; rsi = src2
    ; rdx = dst
    ; ecx = filas
    ; r8d = cols

    push rbp
    mov rbp, rsp

    imul ecx, r8d                          ; exc = cantidad de píxeles

    .ciclo:
        sub ecx, 4                         ; decremento el contador de píxeles
        cmp ecx, 0
        jl .fin
        movdqu xmm0, [rdi]                 ; me traigo los píxeles de ambas imágenes
        movdqu xmm1, [rsi]

        ; calculo el módulo de las diferencias:
        pxor xmm7, xmm7                    ; xmm7 <- 0
        movdqu xmm2, xmm0                  ; xmm2 <- píxeles de src
        movdqu xmm3, xmm1                  ; xmm3 <- píxeles de src_2
        punpcklbw xmm2, xmm7               ; desempaqueto las partes bajas
        punpcklbw xmm3, xmm7
        pcmpgtw xmm2, xmm3                 ; xmm2 <- máscara de partes bajas

        movdqu xmm3, xmm0                  ; xmm3 <- píxeles de src
        movdqu xmm4, xmm1                  ; xmm4 <- píxeles de src_2
        punpckhbw xmm3, xmm7               ; desempaqueto las partes altas
        punpckhbw xmm4, xmm7
        pcmpgtw xmm3, xmm4                 ; xmm3 <- máscara de partes altas

        packsswb xmm2, xmm3                ; xmm2 <- máscara completa

        movdqu xmm3, xmm0                  ; xmm3 <- píxeles de src
        psubusb xmm0, xmm1                 ; xmm0 <- src - src_2
        psubusb xmm1, xmm3                 ; xmm1 <- src_2 - src
        pand xmm0, xmm2                    ; me quedo con los que corresponden de src
        vpandn xmm1, xmm2, xmm1            ; me quedo con los que corresponden de src_2
        por xmm0, xmm1                     ; combino las diferencias

        ; xmm0 = módulo de la diferencia de píxeles

        ; calculo la norma infinito:
        movdqu xmm1, xmm0                  ; xmm1 = b1 | g1 | r1 | a1 | ...
        pslldq xmm1, 1                     ; xmm1 =  0 | b1 | g1 | r1 | 0 | ...
        pmaxub xmm1, xmm0                  ; xmm1 =  x | max(g1, b1) | x | x | ...
        pslldq xmm1, 1                     ; xmm1 =  0 | x | max(g1, b1) | x | ...
        pmaxub xmm0, xmm1                  ; xmm0 =  x | x | max1 | x | ...
        pshufb xmm0, [mask_r_to_bgr]       ; xmm0 = max1 | max1 | max1 | 0 | ...
        por xmm0, [mask_alpha_to_ones]     ; xmm0 = max1 | max1 | max1 | 255 | ...

        ; guardo el valor obtenido en memoria:
        movdqu [rdx], xmm0
        
        ; avanzo los punteros
        add rdi, 0x10
        add rsi, 0x10
        add rdx, 0x10

        jmp .ciclo
        
    .fin:
        pop rbp
        ret
