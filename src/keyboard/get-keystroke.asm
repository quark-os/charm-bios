; Blocks until keystroke is read
; AL = ASCII code of keystroke
getKeystroke:
	MOV CX, 1
	MOV AH, 0x00
	INT 0x16
	RET
