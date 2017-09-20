org 0

XOR AX, AX
MOV SS, AX
MOV SP, 0xFFFC

MOV AX, 0x000D
INT 0x10

MOV AX, 0x0C03
MOV DX, 0
colorloop:
	MOV CX, 0
	xloop:
		INT 0x10
		INC CX
		CMP CX, 0
	JNE xloop
	INC AL
JMP colorloop


times 65536-($-$$) db 0
