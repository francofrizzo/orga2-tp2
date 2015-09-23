  default rel
global _blur_asm
global blur_asm

extern afectarPixel
extern matrizDeConvolucion

section .data



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

		call afectarPixel
		
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

pop r10
; r10 = cols

push rbp
mov rbp, rsp
push r12
push r13
push r14
push r15

;mov r12, rdi + cols * l + h * 4; r12 esta apuntando al pixel a aefctar en la matriz entrada
;mov r13, r12 - radio - radio * cant columnas ; r13 esta apuntando al primer pixel que tengo que usar para afectarlo
;mov r14, rsi + cols * l + h * 4; r14 esta apuntando al pixel a aefctar en la matriz salida

mov r11, r9 
shl r11, 1
inc r11 
;mul r11, r11		; mov r11, (radio*2 + 1)²

mov r15, r9 
shl r15, 1
inc r15 ; mov r15, (radio*2 + 1)

pxor xmm6, xmm6 ;tenemos la suma de los pixels multiplicados
pxor xmm7, xmm7

.ciclo1:
	cmp r11, 0 ;r11 es el contador
	je .yaRecorriLaImagen
	cmp r15, 4 ;r15 es el contador
	jl .cuantosPixelsQuedan? ;caso borde, me quedan menos que 4 


	movdqu xmm0, [r13] ;copiamos los 4 pixels de la imagen de entrada en xmm0
	movdqu xmm1, [rdx] ;copiamos los 4 valores de la matriz de convolucion 
	movdqu xmm2, xmm0 ;usamos xmm2 y dejamos los 4 pixels en xmm0 para no perderlos
	
	;primer pixel:
	
	punpcklbw xmm2, xmm7 
	movdqu xmm4, xmm2 
	punpcklwd xmm2, xmm7 
	punpckhwd xmm4, xmm7 ;xmm4 tenemos el segundo pixel extendido de xmm0

	pshufd xmm1, xmm3, 0x00 ;en xmm3 pusimos el primer valor de xmm1(matriz de conv) 4 veces
	mulps xmm2, xmm3 ;pisamos el pixel con la multiplicacion
	addps xmm6, xmm2 ;sumamos el pixel 

	;segundo pixel:
	
	pshufd xmm1, xmm3, 01010101 ;en xmm3 pusimos el segundo valor de xmm1(matriz de conv) 4 veces
	mulps xmm4, xmm3 ;en xmm4 tenemos el segundo pixel luego de la multiplicacion
	addps xmm6, xmm4 ;sumamos el pixel

	;tercer pixel:

	punpckhbw xmm2, xmm7
	movdqu xmm4, xmm2
	punpcklwd xmm2, xmm7 
	punpckhwd xmm4, xmm7 ;en xmm4 tenemos el 4to pixel extendido de xmm0

	pshufd xmm1, xmm3, 10101010 
	mulps xmm2, xmm3
	addps xmm6, xmm2

	;cuarto pixel

	pshufd xmm1, xmm3, 11111111
	mulps xmm4, xmm3
	addps xmm6, xmm4

	;avanzamos
	add r13, 16
	add rdx, 16
	sub r15, 4
	sub r11, 4
	jmp .ciclo1

.cuantosPixelsQuedan?:
	cmp r15, 0
	je .noQuedaNada
	cmp r15, 1
	je .quedaUno
	cmp r15, 2
	je .quedanDos
	jmp .quedanTres


.noQuedaNada:
	mov r8, r9 ;r9 tiene el radio
	shl r8, 1 
	inc r8 ; r8 = radio * 2 + 1
	mov r12, r10
	sub r12, r8
	shl r12, 2 ; r12 = (cantCols - (radios * 2 + 1) ) * 4

	add r13, r12
	mov r15, r8
	jmp .ciclo1

.quedaUno:
	



;PONER EN 255!!!!!!!!!!!!!!!!

pop r15
pop r14
pop r13
pop r12
pop rbp
ret
