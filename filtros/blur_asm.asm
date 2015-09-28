default rel
global _blur_asm
global blur_asm

;extern afectarPixel
extern matrizDeConvolucion

section .data

	; mask_last_byte_to_ones: DQ 0x0000000000000000, 0x00000000000000ff

section .text
;void blur_asm    (unsigned char *src, unsigned char *dst, int cols, int filas, float sigma, int radius)

_blur_asm:
blur_asm:

	; stack frame:
	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	sub rsp, 8

	mov rbx, rdi ;en rbx guardamos la imagen de entrada
	mov r12, rsi ;en r12 guardamos la imagen de salida
	mov r13, rcx ;en r13 guardamos cantidad de filas
	mov r15, rdx ;en r15 guardamos la cantidad de columnas
	;xmm0 esta el sigma
	mov r14, r8 ;en r14 guardamos el radio

	mov r9, r13 ; r9= filas/2
	shr r9, 1
	cmp r9, r14
	jl .seVaDeRangoElRadio ;si radio > filas/2 no se puede

	mov r9, r15 ; r9= columnas/2
	shr r9, 1
	cmp r9, r14
	jl .seVaDeRangoElRadio ;si radio > columnas/2 no se puede

	;hasta aca tenemos el primer if

	mov rdi, r14 ;en xmm0 esta el sigma
	call matrizDeConvolucion
	mov r11, rax 
	;r11 esta el puntero a matriz de conv

	;inicializamos l y h para el for
	mov r9, r14 ; r9 = l
	mov r8, r14 ; r8 = h
	shl r8, 2 ; r8 * 4

	.ciclo:
		;cmp r9, (r13 - r14) queremos ver si nos fuimos de las filas
		mov r10, r13
		sub r10, r14
		cmp r9, r10
		je .yaRecorriLaFoto

		.ciclo2: 
			;cmp r8, ((r15 - r14)*4) vemos si nos vamos de las columnas
			mov r10, r15
			sub r10, r14
			shl r10, 2 ; r10 * 4
			cmp r8, r10
			je .yaRecorriLaFila
		
			;void afectarPixel(unsigned char *src, unsigned char *dst, float* matConv, int l, int h, int radius, int cols)
			push r9

			mov rdi, rbx
			mov rsi, r12
			mov rdx, r11  
			mov rcx, r9 
			;mov r8, r8 
			mov r9, r14
			;mov algo, r15
			push r8
			push r11
			push r15
	
			call afectarPixel_asm
		
			pop r15
			pop r11
			pop r8
			pop r9
			
			add r8, 4
			jmp .ciclo2

	.yaRecorriLaFila:
		mov r8, r14
		shl r8, 2 ; r8 * 4
		inc r9
		jmp .ciclo

	.seVaDeRangoElRadio:
	.yaRecorriLaFoto:
		add rsp, 8
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbx
		pop rbp
		ret

afectarPixel_asm:
	; void afectarPixel(unsigned char *src, unsigned char *dst, float* matConv, int l, int h, int radius, int cols)
	; rdi = primera img
	; rsi = img salida
	; rdx = matConv
	; rcx = l
	; r8 = h
	; r9 = radio

	mov r10, [rsp + 8]   ; traemos parámetro de la pila ; r10 = cols

	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15

	mov r15, rdx ; r15 = dirección matriz de convolución (para poder usar rdx)

	mov rax, r10 ; rax = cols
	shl rax, 2   ; rax = cols * 4
	mul rcx ; en rax tengo (cols * 4 * l)

	add r8, rax ; en r8 tengo (cols * 4 * l + h)
	mov r12, rdi
	add r12, r8 ; r12 esta apuntando al pixel a afectar en la matriz entrada

	mov r14, rsi
	add r14, r8 ; r14 esta apuntando al pixel a afectar en la matriz salida

	mov r13, r12  ; r13 = pixel afectado matriz entrada
	mov rax, r10  ; rax = cols
	shl rax, 2    ; rax = cols * 4
	mul r9        ; rax = radio * cols * 4
	mov r8, r9    ; r8 = radio
	shl r8, 2     ; r8 = radio * 4
	add rax, r8   ; rax = radio * 4 * (cols + 1)
	sub r13, rax  ; r13 esta apuntando al primer pixel que tengo que usar para afectarlo

	mov r11, r9   ; r11 = radio
	shl r11, 1    ; r11 = radio * 2
	inc r11       ; r11 = radio * 2 + 1

	mov rax, r11
	mul r11       ; rax = r11 * r11
	mov r11, rax  ; r11 = r11 * r11

	mov rdx, r15  ; rdx = matriz de convolucion

	mov r15, r9   ; r15 = radio
	shl r15, 1    ; r15 = radio * 2
	inc r15       ; r15 = radio*2 + 1 (ancho fila a afectar)

	pxor xmm6, xmm6  ; xmm6 = 0 (acá vamos a ir sumando los resultados)
	pxor xmm7, xmm7  ; xmm7 = 0 (este será nuestro registro con ceros)

	.ciclo1:  ; recorremos la submatriz imagen
		cmp r11, 3 ; nos fijamos si estamos en el antepenultimo de todos los píxeles
		je .esElAntepenultimo
		cmp r11, 1 ; nos fijamos si es el ultimo de todos los píxeles
		je .esElUltimo 
		cmp r15, 3 ; nos fijamos si es el antepenultimo de la fila
		je .quedanTres
		cmp r15, 1 ; nos fijamos si es el ultimo de la fila
		je .quedaUno

		movdqu xmm0, [r13] ; copiamos los 4 pixeles de la imagen de entrada en xmm0 ; xmm0 = b4 | g4 | r4 | a4 | ... | a1 (b)
		movdqu xmm1, [rdx] ; copiamos los 4 valores de la matriz de convolucion ; xmm1 = c4 | c3 | c2 | c1 (sp)
		movdqu xmm2, xmm0 ; usamos xmm2 y dejamos los 4 pixels en xmm0 para no perderlos
		
		; desempaquetamos píxeles 1 y 2
		punpcklbw xmm2, xmm7   ; xmm2 = 0 | b2 | 0 | g2 | 0 | r2 | 0 | a2 | ... | 0 | a1
		movdqu xmm4, xmm2    ; xmm4 = xmm2
		punpcklwd xmm2, xmm7 ; xmm2 = 0 | 0 | 0 | b1 | ... | 0 | 0 | 0 | a1
		punpckhwd xmm4, xmm7 ; xmm2 = 0 | 0 | 0 | b2 | ... | 0 | 0 | 0 | a2

		cvtdq2ps xmm2, xmm2  ; convertimos el píxel 1 a float
		cvtdq2ps xmm4, xmm4  ; convertimos el píxel 2 a float
		
		; procesamos píxel 1:
		pshufd xmm3, xmm1, 00000000b ; xmm3 = c1 | c1 | c1 | c1
		mulps xmm2, xmm3 ; xmm2 = c1 * b1 | c1 * g1 | c1 * r1 | c1 * a1
		addps xmm6, xmm2 ; xmm6 = xmm6 + xmm2

		; procesamos píxel 2:
		pshufd xmm3, xmm1, 01010101b ; xmm3 = c2 | c2 | c2 | c2
		mulps xmm4, xmm3 ; xmm4 = c2 * b2 | c2 * g2 | c2 * r2 | c2 * a2
		addps xmm6, xmm4 ; xmm6 = xmm6 + xmm4

		; desempaquetamos píxeles 3 y 4
		punpckhbw xmm0, xmm7   ; xmm0 = 0 | b4 | 0 | g4 | 0 | r4 | 0 | a4 | ... | 0 | a3
		movdqu xmm2, xmm0    ; xmm2 = xmm0
		punpcklwd xmm0, xmm7 ; xmm2 = 0 | 0 | 0 | b3 | ... | 0 | 0 | 0 | a3
		punpckhwd xmm2, xmm7 ; xmm2 = 0 | 0 | 0 | b4 | ... | 0 | 0 | 0 | a4

		cvtdq2ps xmm0, xmm0  ; convertimos el píxel 3 a float
		cvtdq2ps xmm2, xmm2  ; convertimos el píxel 4 a float
		
		; procesamos píxel 3:
		pshufd xmm3, xmm1, 10101010b ; xmm3 = c3 | c3 | c3 | c3
		mulps xmm0, xmm3 ; xmm2 = c3 * b3 | c3 * g3 | c3 * r3 | c3 * a3
		addps xmm6, xmm0 ; xmm6 = xmm6 + xmm0

		; procesamos píxel 4:
		pshufd xmm3, xmm1, 11111111b ; xmm3 = c4 | c4 | c4 | c4
		mulps xmm2, xmm3 ; xmm2 = c4 * b4 | c4 * g4 | c4 * r4 | c4 * a4
		addps xmm6, xmm2 ; xmm6 = xmm6 + xmm2

		;avanzamos
		add r13, 16 ; r13 = r13 + 16 (Avanzo cuatro pixeles en submatriz imagen)
		add rdx, 16 ; rdx = rdx + 16 (Avanzo cuatro pixeles en matriz convolucion)
		sub r15, 4 ; r15 = r15 - 4 (cuantos quedan en la fila)
		sub r11, 4 ; r11 = r11 - 4 (cuantos quedan en total)
		jmp .ciclo1 ; repetimos el ciclo

	.quedaUno:
		movdqu xmm0, [r13]
		punpcklbw xmm0, xmm7 
		punpcklwd xmm0, xmm7
		cvtps2dq xmm0, xmm0  ; convertimos el píxel a float

		;cmp r8, r13 ;en r8 esta el puntero al primero de la matriz de conv. 
		;je .esElPrimeroDeMatConv

		sub rdx, 12 ;ACA CAMBIE ANTES DECIA "sub rdx, 3" - MANU
		movdqu xmm1, [rdx]
		pshufd xmm1, xmm1, 11111111b
		mulps xmm1, xmm0
		addps xmm6, xmm1

		dec r11 ;r11 es el contador, se fija si ya recorrimos toda la imagen

		mov rax, r9 ;r9 tiene el radio
	 	shl rax, 1 
	 	inc rax ; rax = radio * 2 + 1
	 	mov r15, rax

	 	mov r12, r10
	 	sub r12, rax
	 	shl r12, 2 ; r12 = (cantCols - (radios * 2 + 1) ) * 4

	 	add r13, r12

	 	add rdx, 16 ; avanzamos 4 valores de la matriz de conv porque antes restamos 3 

	 	jmp .ciclo1

	.quedanTres:

		movdqu xmm0, [r13] ; copiamos los 4 pixeles de la imagen de entrada en xmm0 ; xmm0 = * | * | * | * | b3 | g3 | r3 | a3 | ... | a1 (b)
		movdqu xmm1, [rdx] ; copiamos los 4 valores de la matriz de convolucion ; xmm1 = * | c3 | c2 | c1 (sp)
		movdqu xmm2, xmm0 ; usamos xmm2 y dejamos los 4 pixels en xmm0 para no perderlos
		
		; desempaquetamos píxeles 1 y 2
		punpcklbw xmm2, xmm7   ; xmm2 = 0 | b2 | 0 | g2 | 0 | r2 | 0 | a2 | ... | 0 | a1
		movdqu xmm4, xmm2    ; xmm4 = xmm2
		punpcklwd xmm2, xmm7 ; xmm2 = 0 | 0 | 0 | b1 | ... | 0 | 0 | 0 | a1
		punpckhwd xmm4, xmm7 ; xmm2 = 0 | 0 | 0 | b2 | ... | 0 | 0 | 0 | a2

		cvtdq2ps xmm2, xmm2  ; convertimos el píxel 1 a float
		cvtdq2ps xmm4, xmm4  ; convertimos el píxel 2 a float
		
		; procesamos píxel 1:
		pshufd xmm3, xmm1, 00000000b ; xmm3 = c1 | c1 | c1 | c1
		mulps xmm2, xmm3 ; xmm2 = c1 * b1 | c1 * g1 | c1 * r1 | c1 * a1
		addps xmm6, xmm2 ; xmm6 = xmm6 + xmm2

		; procesamos píxel 2:
		pshufd xmm3, xmm1, 01010101b ; xmm3 = c2 | c2 | c2 | c2
		mulps xmm4, xmm3 ; xmm4 = c2 * b2 | c2 * g2 | c2 * r2 | c2 * a2
		addps xmm6, xmm4 ; xmm6 = xmm6 + xmm4

		; desempaquetamos pixel 3
		punpckhbw xmm0, xmm7   ; xmm0 = 0 | * | ... | 0 | a3
		movdqu xmm2, xmm0    ; xmm2 = xmm0
		punpcklwd xmm0, xmm7 ; xmm2 = 0 | 0 | 0 | b3 | ... | 0 | 0 | 0 | a3

		cvtdq2ps xmm0, xmm0  ; convertimos el píxel 3 a float
		
		; procesamos píxel 3:
		pshufd xmm3, xmm1, 10101010b ; xmm3 = c3 | c3 | c3 | c3
		mulps xmm0, xmm3 ; xmm2 = c3 * b3 | c3 * g3 | c3 * r3 | c3 * a3
		addps xmm6, xmm0 ; xmm6 = xmm6 + xmm0

		; avanzamos
		mov rax, r9 ; rax = radio
	 	shl rax, 1  ; rax = radio * 2
	 	inc rax     ; rax = radio * 2 + 1
		
	 	mov r12, r10  ; r12 = cols
	 	sub r12, rax  ; r12 = r12 - (radio * 2 + 1)
	 	shl r12, 2    ; r12 = (cols - (radio * 2 + 1) ) * 4
	 	add r13, r12  ; r13 = r13 + r12 (avanzo al inicio de la sig fila en submatriz imagen)
	 	
		add rdx, 12 ; rdx = rdx + 12 (avanzo tres pixeles en matriz convolucion)
				
	 	mov r15, rax ; r15 = radio * 2 + 1 (cuántos quedan en la fila)
		sub r11, 3 ; r11 = r11 - 3 (cuantos quedan en total)
		jmp .ciclo1 ; repetimos el ciclo

	.esElAntepenultimo:
		sub rdx, 4
		movdqu xmm0, [rdx]

		sub r13, 4
		movdqu xmm1, [r13] 

		movdqu xmm2, xmm1 ;no queremos perder los pixels 

		punpcklbw xmm2, xmm7 ;pixel 1 y nada 
		punpckhwd xmm2, xmm7 

		pshufd xmm3, xmm0, 01010101b
		mulps xmm2, xmm3
		addps xmm6, xmm2

		punpckhbw xmm1, xmm7
		movdqu xmm2, xmm1

		punpcklwd xmm1, xmm7 
		pshufd xmm3, xmm0, 10101010b
		mulps xmm3, xmm1
		addps xmm6, xmm3

		punpckhwd xmm2, xmm7
		pshufd xmm3, xmm0, 11111111b
		mulps xmm3, xmm2
		addps xmm6, xmm3  

		jmp .fin 

	.esElUltimo:
		sub rdx, 12
		movdqu xmm0, [rdx]

		sub r13, 12
		movdqu xmm1, [r13]

		pshufd xmm0, xmm0, 11111111b

		punpckhbw xmm1, xmm7
		punpckhwd xmm1, xmm7

		mulps xmm1, xmm0
		addps xmm6, xmm1

		jmp .fin

	.fin:
		cvtps2dq xmm6, xmm6

		packssdw xmm6, xmm7

		packsswb xmm6, xmm7

		; pshufd xmm6, xmm6, 00100111b

		; por xmm6, [mask_last_byte_to_ones]
		; movd [r14], xmm6

		movd r8d, xmm6
		or r8d, 0xff000000
		; mov r8d, 0xff0000ff
		mov [r14], r8d

	;PONER EN 255!!!!!!!!!!!!!!!! Y GUARDAR TODO EL PIXEL
	;en xmm6 tenemos la suma y en r14 esta el puntero al pixel que hay que afectar en la imagen de salida
	;cuando lo probemos hay que sacar el "extern afectarPixel" 

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret
