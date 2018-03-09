backspace:
	MOV AH, 0x03
	CMP DL, 0
	JE _backcolumn
	DEC DL
	JMP _writespace
	_backcolumn:
	MOV DL, 80
	DEC DH
	_writespace:
	MOV AH, 0x02
	INT 0x10
	MOV AL, ' '
	MOV AH, 0x0A
	MOV BX, 0x000F
	MOV CX, 2
	INT 0x10
	RET
