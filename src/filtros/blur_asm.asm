default rel
global _blur_asm
global blur_asm

extern matrizDeConvolucion

section .data

section .text
; void blur_asm (unsigned char *src, unsigned char *dst, int cols, int filas, float sigma, int radius)

_blur_asm:
blur_asm:

    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub  rsp, 8

    mov  rbx, rdi                   ; rbx = imagen de entrada
    mov  r12, rsi                   ; r12 = imagen de salida
    mov  r13d, ecx                  ; r13d = cantidad de filas
    mov  r15d, edx                  ; r15d = cantidad de columnas
                                    ; en xmm0 está sigma
    mov  r14d, r8d                  ; r14d = radio

    mov  r9d, r13d                  ; r9d = filas
    shr  r9d, 1                     ; r9d = filas/2
    cmp  r9d, r14d                  ; si radio > filas/2 no se puede
    jl   .seVaDeRangoElRadio

    mov  r9d, r15d                  ; r9d = columnas
    shr  r9d, 1                     ; r9d = columnas/2
    cmp  r9d, r14d                  ; si radio > columnas/2 no se puede
    jl   .seVaDeRangoElRadio 

    mov  edi, r14d                  ; edi = radio
    call matrizDeConvolucion
    mov  r11, rax                   ; r11 = puntero a matriz de convolución

                                    ; inicializamos l y h para el for
    mov  r9d, r14d                  ; r9d = l
    mov  r8d, r14d                  ; r8d = h
    shl  r8d, 2                     ; r8d = r8d * 4

    .ciclo:
        mov  r10d, r13d             ; cmp r9d, (r13d - r14d) queremos ver si nos fuimos de las filas
        sub  r10d, r14d
        cmp  r9d, r10d
        je   .yaRecorriLaFoto

        .ciclo2: 
            mov  r10d, r15d         ; cmp r8d, ((r15d - r14d) * 4) vemos si nos vamos de las columnas
            sub  r10d, r14d
            shl  r10d, 2            ; r10d = r10d * 4
            cmp  r8d, r10d
            je   .yaRecorriLaFila
        
            ;void afectarPixel (unsigned char *src, unsigned char *dst, float* matConv, int l, int h, int radius, int cols)
            ; push r9

            ; mov  rdi, rbx
            ; mov  rsi, r12
            ; mov  rdx, r11
            ; mov  ecx, r9d 
            ; mov  r9d, r14d
            ; push r8
            ; push r11
            ; push r15
    
            ; void afectarPixel(unsigned char *src, unsigned char *dst, float* matConv, int l, int h, int radius, int cols)
            ; rdi = primera img
            ; rsi = img salida
            ; rdx = matConv
            ; ecx = l
            ; r8d = h
            ; r9d = radio

            ; comienzo de afectarPixel

            and  rcx, 0x0000ffff    ; rcx = e8d
            and  r8, 0x0000ffff     ; r8 = r8d
            and  r9, 0x0000ffff     ; r8 = r8d

            xor  r10, r10           ; r10 = 0
            mov  r10, [rsp + 8]     ; traemos parámetro de la pila ; r10 = cols

            push rbp
            mov  rbp, rsp
            push r12
            push r13
            push r14
            push r15

            mov  r15, rdx           ; r15 = dirección matriz de convolución (para poder usar rdx)

            mov  rax, r10           ; rax = cols
            shl  rax, 2             ; rax = cols * 4
            mul  rcx                ; en rax tengo (cols * 4 * l)

            add  r8, rax            ; en r8 tengo (cols * 4 * l + h)
            mov  r12, rdi
            add  r12, r8            ; r12 esta apuntando al píxel a afectar en la matriz entrada

            mov  r14, rsi
            add  r14, r8            ; r14 esta apuntando al píxel a afectar en la matriz salida

            mov  r13, r12           ; r13 = píxel afectado matriz entrada
            mov  rax, r10           ; rax = cols
            shl  rax, 2             ; rax = cols * 4
            mul  r9                 ; rax = radio * cols * 4
            mov  r8, r9             ; r8 = radio
            shl  r8, 2              ; r8 = radio * 4
            add  rax, r8            ; rax = radio * 4 * (cols + 1)
            sub  r13, rax           ; r13 esta apuntando al primer píxel que tengo que usar para afectarlo

            mov  r11, r9            ; r11 = radio
            shl  r11, 1             ; r11 = radio * 2
            inc  r11                ; r11 = radio * 2 + 1

            mov  rax, r11
            mul  r11                ; rax = r11 * r11
            mov  r11, rax           ; r11 = r11 * r11

            mov  rdx, r15           ; rdx = matriz de convolución

            mov  r15, r9            ; r15 = radio
            shl  r15, 1             ; r15 = radio * 2
            inc  r15                ; r15 = radio*2 + 1 (ancho fila a afectar)

            pxor xmm6, xmm6         ; xmm6 = 0 (acá vamos a ir sumando los resultados)
            pxor xmm7, xmm7         ; xmm7 = 0 (este será nuestro registro con ceros)

            .ciclo:                                 ; recorremos la submatriz imagen
                                                    ; r11 = cuántos píxeles quedan en total
                                                    ; r15 = cuántos píxeles quedan en la fila
                cmp     r11, 1                      ; nos fijamos si es el último de todos los píxeles
                je      .esElUltimo
                cmp     r11, 3                      ; nos fijamos si estamos en el antepenúltimo de todos los píxeles
                je     .esElAntepenultimo

                                                    ; si todavía quedan muchos píxeles:
                movdqu xmm0, [r13]                  ; copiamos los 4 píxeles de la imagen de entrada en xmm0
                                                    ; xmm0 = b4 | g4 | r4 | a4 | ... | a1 (b)
                movdqu xmm1, [rdx]                  ; copiamos los 4 valores de la matriz de convolución
                                                    ; xmm1 = c4 | c3 | c2 | c1 (sp)
                jmp    .procesarPixeles

                .esElUltimo:                        ; si es el último píxel
                    movdqu xmm0, [r13 - 12]         ; xmm0 = b | g | r | a | ... | * | * | * | * (b)
                    movdqu xmm1, [rdx - 12]         ; xmm1 = c | * | * | * (sp)
                    pslldq xmm0, 12                 ; xmm0 = 0 | 0 | 0 | 0 | ... | b | g | r | a (b)
                    pslldq xmm1, 12                 ; xmm1 = 0 | 0 | 0 | c (sp)
                    jmp    .procesarPixeles

                .esElAntepenultimo:                 ; si es el antepenúltimo píxel
                    movdqu xmm0, [r13 - 4]          ; xmm0 = b3 | g3 | r3 | a3 | b2 | ... | a1 | * | * | * | * (b)
                    movdqu xmm1, [rdx - 4]          ; xmm1 = c3 | c2 | c1 | * (sp)
                    pslldq xmm0, 4                  ; xmm0 = 0 | 0 | 0 | 0 | b3 | g3 | ... | b1 | g1 | r1 | a1 (b)
                    pslldq xmm1, 4                  ; xmm1 = 0 | c3 | c2 | c1 (sp)
                    jmp    .procesarPixeles
                
                .procesarPixeles:
                    movdqu    xmm2, xmm0            ; usamos xmm2 y dejamos los 4 píxeles en xmm0 para no perderlos
                    
                                                    ; desempaquetamos píxeles 1 y 2
                    punpcklbw xmm2, xmm7            ; xmm2 = 0 | b2 | 0 | g2 | 0 | r2 | 0 | a2 | ... | 0 | a1
                    movdqu    xmm4, xmm2            ; xmm4 = xmm2
                    punpcklwd xmm2, xmm7            ; xmm2 = 0 | 0 | 0 | b1 | ... | 0 | 0 | 0 | a1
                    punpckhwd xmm4, xmm7            ; xmm2 = 0 | 0 | 0 | b2 | ... | 0 | 0 | 0 | a2

                    cvtdq2ps  xmm2, xmm2            ; convertimos el píxel 1 a float
                    cvtdq2ps  xmm4, xmm4            ; convertimos el píxel 2 a float
                    
                                                    ; procesamos píxel 1:
                    pshufd    xmm3, xmm1, 00000000b ; xmm3 = c1 | c1 | c1 | c1
                    mulps     xmm2, xmm3            ; xmm2 = c1 * b1 | c1 * g1 | c1 * r1 | c1 * a1
                    addps     xmm6, xmm2            ; xmm6 = xmm6 + xmm2

                    add       r13, 4                ; r13 = r13 + 4 (avanzo un píxel en submatriz imagen)
                    add       rdx, 4                ; rdx = rdx + 4 (avanzo un píxel en matriz de convolución)
                    dec       r15                   ; r15-- (cuántos quedan en la fila)
                    dec       r11                   ; r11-- (cuántos quedan en total)

                    cmp       r15, 0                ; vemos si quedan píxeles para procesar en la fila
                    je        .avanzar

                                                    ; procesamos píxel 2:
                    pshufd    xmm3, xmm1, 01010101b ; xmm3 = c2 | c2 | c2 | c2
                    mulps     xmm4, xmm3            ; xmm4 = c2 * b2 | c2 * g2 | c2 * r2 | c2 * a2
                    addps     xmm6, xmm4            ; xmm6 = xmm6 + xmm4

                    add       r13, 4                ; r13 = r13 + 4 (avanzo un píxel en submatriz imagen)
                    add       rdx, 4                ; rdx = rdx + 4 (avanzo un píxel en matriz de convolución)
                    dec       r15                   ; r15-- (cuántos quedan en la fila)
                    dec       r11                   ; r11-- (cuántos quedan en total)

                                                    ; desempaquetamos píxeles 3 y 4
                    punpckhbw xmm0, xmm7            ; xmm0 = 0 | b4 | 0 | g4 | 0 | r4 | 0 | a4 | ... | 0 | a3
                    movdqu    xmm2, xmm0            ; xmm2 = xmm0
                    punpcklwd xmm0, xmm7            ; xmm2 = 0 | 0 | 0 | b3 | ... | 0 | 0 | 0 | a3
                    punpckhwd xmm2, xmm7            ; xmm2 = 0 | 0 | 0 | b4 | ... | 0 | 0 | 0 | a4

                    cvtdq2ps  xmm0, xmm0            ; convertimos el píxel 3 a float
                    cvtdq2ps  xmm2, xmm2            ; convertimos el píxel 4 a float
                    
                                                    ; procesamos píxel 3:
                    pshufd    xmm3, xmm1, 10101010b ; xmm3 = c3 | c3 | c3 | c3
                    mulps     xmm0, xmm3            ; xmm2 = c3 * b3 | c3 * g3 | c3 * r3 | c3 * a3
                    addps     xmm6, xmm0            ; xmm6 = xmm6 + xmm0

                    add       r13, 4                ; r13 = r13 + 4 (avanzo un píxel en submatriz imagen)
                    add       rdx, 4                ; rdx = rdx + 4 (avanzo un píxel en matriz de convolución)
                    dec       r15                   ; r15-- (cuántos quedan en la fila)
                    dec       r11                   ; r11-- (cuántos quedan en total)

                    cmp       r15, 0                ; vemos si quedan píxeles para procesar en la fila
                    je        .avanzar

                                                    ; procesamos píxel 4:
                    pshufd    xmm3, xmm1, 11111111b ; xmm3 = c4 | c4 | c4 | c4
                    mulps     xmm2, xmm3            ; xmm2 = c4 * b4 | c4 * g4 | c4 * r4 | c4 * a4
                    addps     xmm6, xmm2            ; xmm6 = xmm6 + xmm2

                    add       r13, 4                ; r13 = r13 + 4 (avanzo un píxel en submatriz imagen)
                    add       rdx, 4                ; rdx = rdx + 4 (avanzo un píxel en matriz de convolución)
                    dec       r15                   ; r15-- (cuántos quedan en la fila)
                    dec       r11                   ; r11-- (cuántos quedan en total)

                .avanzar:
                    cmp       r15, 0          ; vemos si quedan píxeles en la fila
                    jne       .ciclo          ; si quedan, repetimos el ciclo

                    cmp       r11, 0          ; vemos si la fila era la última
                    je        .fin            ; si era, terminamos el ciclo

                                              ; si no era la última fila, avanzamos a la siguiente
                    mov       rax, r9         ; rax = radio
                    shl       rax, 1          ; rax = radio * 2
                    inc       rax             ; rax = radio * 2 + 1
                    
                    mov       r12, r10        ; r12 = cols
                    sub       r12, rax        ; r12 = r12 - (radio * 2 + 1)
                    shl       r12, 2          ; r12 = (cols - (radio * 2 + 1) ) * 4
                    add       r13, r12        ; r13 = r13 + r12 (avanzo al inicio de la sig fila en submatriz imagen)
                    
                    mov       r15, rax        ; r15 = radio * 2 + 1 (cuántos quedan en la fila)

                    jmp       .ciclo          ; repetimos el ciclo

            .fin:
                cvtps2dq xmm6, xmm6           ; convertimos xxm6 a entero ; xmm6 = b | g | r | a (dw)
                packusdw xmm6, xmm7           ; xmm6 = 0 | 0 | 0 | 0 | b | g | r | a (w)
                packuswb xmm6, xmm7           ; xmm6 = 0 | 0 | 0 | 0 | 0 | ... | 0 | b | g | r | a (b)
                movd     r8d, xmm6            ; r8d = b | g | r | a
                or       r8d, 0xff000000      ; r8d = b | g | r | 0xff
                mov      [r14], r8d           ; guardo en memoria el valor obtenido

            ; pop r15
            ; pop r14
            ; pop r13
            ; pop r12
            ; pop rbp
            ; ret

            ; fin de afectarPixel
        
            ; pop  r15
            ; pop  r11
            ; pop  r8
            ; pop  r9
            
            add  r8d, 4
            jmp  .ciclo2

    .yaRecorriLaFila:
        mov  r8d, r14d
        shl  r8d, 2       ; r8d = r8d * 4
        inc  r9d
        jmp  .ciclo

    .seVaDeRangoElRadio:
    .yaRecorriLaFoto:
        add  rsp, 8
        pop  r15
        pop  r14
        pop  r13
        pop  r12
        pop  rbx
        pop  rbp
        ret
