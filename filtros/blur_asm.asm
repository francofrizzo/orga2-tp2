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
; ... = cols



push rbp
mov rbp, rsp
push r12
push r13
push r14
push r15

;mov r12, rdi + cols * l + h * 4; r12 esta apuntando al pixel a aefctar
;mov r13, r12 - radio - radio * cant columnas ; r13 esta apuntando al primer pixel que tengo que usar para afectarlo





pop r15
pop r14
pop r13
pop r12
pop rbp
ret