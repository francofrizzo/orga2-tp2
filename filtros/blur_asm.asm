  default rel
global _blur_asm
global blur_asm

;extern afectarPixel
extern matrizDeConvolucion

section .data

	; mask_last_byte_to_ones: DQ 0x0000000000000000, 0x00000000000000ff

section .text
;void blur_asm    (unsigned char *src, unsigned char *dst, int filas, int cols, float sigma, int radius)

_blur_asm:


blur_asm:

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
	mov r13, rdx ;en r13 guardamos cantidad de filas
	mov r15, rcx ;en r15 guardamos la cantidad de columnas
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

	mov r10, [rsp + 8]
	; r10 = cols

	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15

	mov r15, rdx ;esto lo cambie, antes habia esto "mov r11, rdx". Necesito multiplicar r11, y r15 lo empiezo a usar mas abajo de eso recien. MANU


	mov rax, r10
	mul rcx ; en rax tengo (cols * l)

	; shl r8, 2 ;en r8 tengo (h*4) ESTO ESTABA MAL!
	add r8, rax ;en r8 tengo (cols * l + h)
	mov r12, rdi
	add r12, r8
	;mov r12, rdi + cols * l + h; r12 esta apuntando al pixel a aefctar en la matriz entrada

	mov r14, rsi
	add r14, r8
	;mov r14, rsi + cols * l + h; r14 esta apuntando al pixel a aefctar en la matriz salida

	mov rax, r10
	mul r9
	mov r8, rax 
	mov r13, r12
	sub r13, r9
	sub r13, r8
	;mov r13, r12 - radio - radio * cant columnas ; r13 esta apuntando al primer pixel que tengo que usar para afectarlo

	;mov rdx, r11. Esto lo comente por lo de mas arriba(al final use r15 para guardar rdx) MANU

	mov r8, rdx ;guardamos el puntero a la matriz de convolucion 

	mov r11, r9 
	shl r11, 1
	inc r11 

	mov rax, r11 ;esto lo agregue - MANU
	mul r11 ;esto lo agregue - MANU ; en rax esta r11 * r11 y en rdx tengo la otra parte que no me importa
	;mul r11, r11		; mov r11, (radio*2 + 1)²

	mov rdx, r15 ;esto lo agregue - MANU

	mov r15, r9 
	shl r15, 1
	inc r15 ; mov r15, (radio*2 + 1)

	pxor xmm6, xmm6 ;tenemos la suma de los pixels multiplicados
	pxor xmm7, xmm7

	.ciclo1:
		cmp r11, 3 ;nos fijamos si estamos en el antepenultimo 
		je .esElAntepenultimo
	;	cmp r11, 2 ;nos fijamos si es el anteultimo 
	;	je .esElAnteultimo 
		cmp r11, 1 ;nos fijamos si es el ultimo
		je .esElUltimo 
	;	cmp r11, 0 ;r11 es el contador, se fija si ya recorrimos toda la imagen
	;	je .yaRecorriLaImagen
		cmp r15, 4 ;r15 es el contador, se fija si ya recorrimos toda una fila
		jl .cuantosPixelsQuedan? ;caso borde, me quedan menos que 4 


		movdqu xmm0, [r13] ;copiamos los 4 pixels de la imagen de entrada en xmm0
		movdqu xmm1, [rdx] ;copiamos los 4 valores de la matriz de convolucion 
		movdqu xmm2, xmm0 ;usamos xmm2 y dejamos los 4 pixels en xmm0 para no perderlos
		
		;primer pixel:
		
		punpcklbw xmm2, xmm7 
		movdqu xmm4, xmm2 
		punpcklwd xmm2, xmm7 
		punpckhwd xmm4, xmm7 ;xmm4 tenemos el segundo pixel extendido de xmm0

		pshufd xmm1, xmm3, 00000000b ;en xmm3 pusimos el primer valor de xmm1(matriz de conv) 4 veces
		mulps xmm2, xmm3 ;pisamos el pixel con la multiplicacion
		addps xmm6, xmm2 ;sumamos el pixel 

		;segundo pixel:
		
		pshufd xmm1, xmm3, 01010101b ;en xmm3 pusimos el segundo valor de xmm1(matriz de conv) 4 veces
		mulps xmm4, xmm3 ;en xmm4 tenemos el segundo pixel luego de la multiplicacion
		addps xmm6, xmm4 ;sumamos el pixel

		;tercer pixel:

		punpckhbw xmm2, xmm7
		movdqu xmm4, xmm2
		punpcklwd xmm2, xmm7 
		punpckhwd xmm4, xmm7 ;en xmm4 tenemos el 4to pixel extendido de xmm0

		pshufd xmm1, xmm3, 10101010b
		mulps xmm2, xmm3
		addps xmm6, xmm2

		;cuarto pixel

		pshufd xmm1, xmm3, 11111111b
		mulps xmm4, xmm3
		addps xmm6, xmm4

		;avanzamos
		add r13, 16 ;4 pixels
		add rdx, 16 ;4 floats de la matriz de conv
		sub r15, 4
		sub r11, 4
		jmp .ciclo1

	.cuantosPixelsQuedan?:
	;	cmp r15, 0
	;	je .noQuedaNada
		cmp r15, 1
		je .quedaUno
	;	cmp r15, 2
	;	je .quedanDos
		jmp .quedanTres


	; .noQuedaNada:
	; 	mov r8, r9 ;r9 tiene el radio
	; 	shl r8, 1 
	; 	inc r8 ; r8 = radio * 2 + 1
	; 	mov r12, r10
	; 	sub r12, r8
	; 	shl r12, 2 ; r12 = (cantCols - (radios * 2 + 1) ) * 4

	; 	add r13, r12
	; 	mov r15, r8
	; 	jmp .ciclo1

	.quedaUno:
		movdqu xmm0, [r13]
		punpcklbw xmm0, xmm7 
		punpcklwd xmm0, xmm7

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

	 ; .esElPrimeroDeMatConv:
		
		; movdqu xmm1, [rdx]
		; pshufw xmm1, 00000000 ;revisar
		; mulps xmm1, xmm0
		; addps xmm6, xmm1

		; dec r11 ;r11 es el contador, se fija si ya recorrimos toda la imagen

		; mov rax, r9 ;r9 tiene el radio
	 ; 	shl rax, 1 
	 ; 	inc rax ; rax = radio * 2 + 1
	 ; 	mov r15, rax ;r15 es un contador, se fija si ya recorrimos toda la fila

	.quedanTres:
		movdqu xmm0, [r13]
		movdqu xmm2, xmm0
		punpcklbw xmm0, xmm7  
		movdqu xmm1, xmm0
		punpckhwd xmm1, xmm7 ;en xmm1 esta el pixel 2 
		punpcklwd xmm0, xmm7 ;en xmm0 esta el pixel 1
		punpckhbw xmm2, xmm7 
		punpcklwd xmm2, xmm7 ;en xmm2 esta el pixel 3

		cmp r8, r13 ;en r8 esta el puntero al primero de la matriz de conv. 
		je .esElPrimeroDeMatConv	

		sub rdx, 4 
		movdqu xmm3, [rdx]
		pshufd xmm4, xmm3, 11111111b ;en xmm4 esta 4 veces el valor 3
		mulps xmm4, xmm2 ;multiplicamos pixel 3
		addps xmm6, xmm4 ;sumamos pixel 3

		pshufd xmm4, xmm3, 10101010b ;en xmm4 esta 4 veces el valor 2
		mulps xmm4, xmm1 ;multiplicamos pixel 2
		addps xmm6, xmm4 ;sumamos pixel 2

		pshufd xmm4, xmm3, 01010101b ;en xmm4 esta 4 veces el valor 1
		mulps xmm4, xmm0 ;multiplicamos pixel 1
		addps xmm6, xmm4 ;sumamos pixel 1

		sub r11, 3 ;r11 es el contador, se fija si ya recorrimos toda la imagen

		mov rax, r9 ;r9 tiene el radio
	 	shl rax, 1 
	 	inc rax ; rax = radio * 2 + 1
	 	mov r15, rax ;r15 se fija si ya recorrimos la fila

	 	mov r12, r10
	 	sub r12, rax
	 	shl r12, 2 ; r12 = (cantCols - (radios * 2 + 1) ) * 4

	 	add r13, r12

	 	add rdx, 16

	 	jmp .ciclo1

	.esElPrimeroDeMatConv:
		movdqu xmm3, [rdx]
		pshufd xmm4, xmm3, 10101010b ;en xmm4 esta 4 veces el valor 3
		mulps xmm4, xmm2 ;multiplicamos pixel 3
		addps xmm6, xmm4 ;sumamos el pixel 3

		pshufd xmm4, xmm3, 01010101b ;en xmm4 esta 4 veces el valor 2
		mulps xmm4, xmm1 ;multiplicamos el pixel 2
		addps xmm6, xmm4 

		pshufd xmm4, xmm3, 00000000b ;en xmm4 esta 4 veces el valor 1
		mulps xmm4, xmm0 ;multiplicamos pixel 1
		addps xmm6, xmm4

		sub r11, 3 ;r11 es el contador, se fija si ya recorrimos toda la imagen

		mov rax, r9 ;r9 tiene el radio
	 	shl rax, 1 
	 	inc rax ; rax = radio * 2 + 1
	 	mov r15, rax ;r15 se fija si ya recorrimos la fila

	 	mov r12, r10
	 	sub r12, rax
	 	shl r12, 2 ; r12 = (cantCols - (radios * 2 + 1) ) * 4

	 	add r13, r12

	 	add rdx, 12

	 	jmp .ciclo1

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
		cvtps2dq xmm7, xmm7 ; aca pasamos de float a integer (DW) xmm6 y xmm7

		packssdw xmm6, xmm7
		packssdw xmm7, xmm7

		packsswb xmm6, xmm7

		pshufd xmm6, xmm6, 00100111b

		; por xmm6, [mask_last_byte_to_ones]
		; movd [r14], xmm6

		movd r8d, xmm6
		or r8d, 0x000000ff
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
