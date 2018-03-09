; Character to print must be in AL
printChar:
	PUSH BX
	; print character
	MOV AH, 0x0A
	MOV BX, 0x000F
	MOV CX, 1
	INT 0x10
	; get cursor position
	MOV AH, 0x03 
	INT 0x10
	; set cursor position
	CMP DL, 80
	JNE _shiftcolumn
	INC DH
	XOR DL, DL
	JMP _setcursor
	_shiftcolumn:
	INC DL
	_setcursor:
	MOV AH, 0x02 
	INT 0x10
	POP BX
	RET
